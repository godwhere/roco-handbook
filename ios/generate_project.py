"""Generate the dependency-free native Xcode project from its owned sources."""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def identity(name: str) -> str:
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def generate(destination: Path | None = None) -> None:
    objects: list[str] = []

    def obj(name: str, body: str) -> str:
        key = identity(name)
        objects.append(f"{key} = {{ {body} }};")
        return key

    def refs(values: list[str]) -> str:
        return "(" + ",".join(values) + ",)"

    app_files: list[str] = []
    source_builds: list[str] = []
    for path in sorted((ROOT / "App").glob("*.swift")):
        relative = path.relative_to(ROOT).as_posix()
        file = obj(relative, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{relative}"; sourceTree = SOURCE_ROOT;')
        app_files.append(file)
        source_builds.append(obj(relative + ":build", f"isa = PBXBuildFile; fileRef = {file};"))
    app_product = obj("app-product", 'isa = PBXFileReference; explicitFileType = wrapper.application; path = RocoHandbook.app; sourceTree = BUILT_PRODUCTS_DIR;')
    test_product = obj("test-product", 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = RocoHandbookUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
    test_source = obj("ui-test-source", 'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = UITests/RocoHandbookUITests.swift; sourceTree = SOURCE_ROOT;')
    test_build = obj("ui-test-build", f"isa = PBXBuildFile; fileRef = {test_source};")
    assets = obj("app-icon", 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "../app/ios/Runner/Assets.xcassets"; sourceTree = SOURCE_ROOT;')
    resources = [obj("app-icon-build", f"isa = PBXBuildFile; fileRef = {assets};")]
    locales: list[str] = []
    for filename in ["Localizable.strings", "InfoPlist.strings"]:
        languages = []
        for language in ["en", "zh-Hans"]:
            languages.append(obj(f"{language}:{filename}", f'isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "{language}"; path = "App/{language}.lproj/{filename}"; sourceTree = SOURCE_ROOT;'))
        group = obj(filename, f"isa = PBXVariantGroup; children = {refs(languages)}; name = {filename}; sourceTree = \"<group>\";")
        locales.append(group)
        resources.append(obj(filename + ":build", f"isa = PBXBuildFile; fileRef = {group};"))
    group = obj("main-group", f'isa = PBXGroup; children = {refs(app_files + [assets] + locales + [test_source, app_product, test_product])}; sourceTree = "<group>";')
    sources = obj("sources", f"isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {refs(source_builds)}; runOnlyForDeploymentPostprocessing = 0;")
    resource_phase = obj("resources", f"isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {refs(resources)}; runOnlyForDeploymentPostprocessing = 0;")
    package = obj("core-package", 'isa = XCLocalSwiftPackageReference; relativePath = .;')
    dependency = obj("core-product", f"isa = XCSwiftPackageProductDependency; package = {package}; productName = HandbookCore;")
    core_build = obj("core-build", f"isa = PBXBuildFile; productRef = {dependency};")
    frameworks = obj("frameworks", f"isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = {refs([core_build])}; runOnlyForDeploymentPostprocessing = 0;")
    script = r'python3 \"$SRCROOT/prepare_resources.py\" --output \"$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/assets\"'
    stage = obj("stage", f'isa = PBXShellScriptBuildPhase; alwaysOutOfDate = 1; buildActionMask = 2147483647; files = (); inputPaths = (); outputPaths = (); runOnlyForDeploymentPostprocessing = 0; shellPath = /bin/sh; shellScript = "{script}"; name = "Stage active offline assets";')
    base = "CLANG_ENABLE_MODULES = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 15.0; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = \"1,2\"; SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\"; SUPPORTS_MACCATALYST = NO; ENABLE_USER_SCRIPT_SANDBOXING = NO; CODE_SIGN_STYLE = Automatic;"

    def configurations(name: str, settings: str) -> str:
        keys = []
        for mode in ["Debug", "Release"]:
            debug = 'SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; ENABLE_TESTABILITY = YES; ONLY_ACTIVE_ARCH = YES;' if mode == "Debug" else 'SWIFT_OPTIMIZATION_LEVEL = "-O"; ONLY_ACTIVE_ARCH = NO;'
            keys.append(obj(f"{name}:{mode}", f"isa = XCBuildConfiguration; buildSettings = {{ {base} {debug} {settings} }}; name = {mode};"))
        return obj(name + ":configurations", f'isa = XCConfigurationList; buildConfigurations = {refs(keys)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

    app_config = configurations("app", 'PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = world.roco.rocoHandbook; INFOPLIST_FILE = App/Info.plist; GENERATE_INFOPLIST_FILE = NO; MARKETING_VERSION = 1.2.0; CURRENT_PROJECT_VERSION = 3; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";')
    app_target = obj("app-target", f"isa = PBXNativeTarget; buildConfigurationList = {app_config}; buildPhases = {refs([sources, frameworks, resource_phase, stage])}; buildRules = (); dependencies = (); name = RocoHandbook; packageProductDependencies = {refs([dependency])}; productName = RocoHandbook; productReference = {app_product}; productType = \"com.apple.product-type.application\";")
    test_sources = obj("test-sources", f"isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {refs([test_build])}; runOnlyForDeploymentPostprocessing = 0;")
    test_frameworks = obj("test-frameworks", "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;")
    proxy = obj("test-proxy", f"isa = PBXContainerItemProxy; containerPortal = {identity('project')}; proxyType = 1; remoteGlobalIDString = {app_target}; remoteInfo = RocoHandbook;")
    test_dependency = obj("test-app-dependency", f"isa = PBXTargetDependency; target = {app_target}; targetProxy = {proxy};")
    test_config = configurations("ui-tests", 'PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = world.roco.rocoHandbook.UITests; GENERATE_INFOPLIST_FILE = YES; TEST_TARGET_NAME = RocoHandbook; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @loader_path/Frameworks";')
    test_target = obj("test-target", f"isa = PBXNativeTarget; buildConfigurationList = {test_config}; buildPhases = {refs([test_sources, test_frameworks])}; buildRules = (); dependencies = {refs([test_dependency])}; name = RocoHandbookUITests; productName = RocoHandbookUITests; productReference = {test_product}; productType = \"com.apple.product-type.bundle.ui-testing\";")
    project_config = configurations("project", "DEVELOPMENT_LANGUAGE = en;")
    project = obj("project", f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2700; }}; buildConfigurationList = {project_config}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, "zh-Hans", Base); mainGroup = {group}; packageReferences = {refs([package])}; projectDirPath = ""; projectRoot = ""; targets = {refs([app_target, test_target])};')
    directory = destination or ROOT / "RocoHandbook.xcodeproj"
    directory.mkdir(exist_ok=True)
    (directory / "project.pbxproj").write_text("// !$*UTF8*$!\n{\narchiveVersion = 1;\nclasses = {};\nobjectVersion = 56;\nobjects = {\n" + "\n".join(objects) + f"\n}};\nrootObject = {project};\n}}\n")
    scheme_directory = directory / "xcshareddata/xcschemes"
    scheme_directory.mkdir(parents=True, exist_ok=True)
    def reference(target: str, product: str, name: str) -> str:
        return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:RocoHandbook.xcodeproj"/>'
    app_ref = reference(app_target, "RocoHandbook.app", "RocoHandbook")
    test_ref = reference(test_target, "RocoHandbookUITests.xctest", "RocoHandbookUITests")
    (scheme_directory / "RocoHandbook.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="NO"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')


if __name__ == "__main__":
    generate()
