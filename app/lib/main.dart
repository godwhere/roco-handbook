import 'package:flutter/material.dart';

import 'catalog_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const bootstrap = ProductionCatalogBootstrap();
  runApp(
    CatalogBootstrapApp(
      bootstrap: bootstrap.load,
      restoreBundledCatalog: bootstrap.restoreBundledCatalog,
      checkForCatalogUpdate: bootstrap.checkForCatalogUpdate,
      installCatalogUpdate: bootstrap.installCatalogUpdate,
    ),
  );
}
