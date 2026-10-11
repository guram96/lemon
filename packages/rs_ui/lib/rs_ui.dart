/// Abstract UI component layer.
///
/// Feature code builds only with the `Rs*` widgets exported here. Each one
/// delegates its look to the active [RsComponentSet] (Steam, Cupertino,
/// Material, Fluent, …) provided by [RsComponents] at the app root.
/// Focus and controller input are shared primitives, so every look behaves
/// the same.
library;

export 'src/component_set.dart';
export 'src/components/rs_button.dart';
export 'src/components/rs_tile.dart';
export 'src/components/rs_toggle.dart';
export 'src/focus/rs_focusable.dart';
export 'src/input/rs_input_scope.dart';
export 'src/input/rs_intents.dart';
