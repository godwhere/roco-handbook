import 'package:flutter/material.dart';

import 'catalog_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    CatalogBootstrapApp(bootstrap: const ProductionCatalogBootstrap().load),
  );
}
