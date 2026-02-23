import 'dart:mirrors';

mixin JsonSerializable {
  Map<String, dynamic> toJson({bool includePrivate = false}) {
    final map = <String, dynamic>{};
    final mirror = reflect(this);
    
    for (final declaration in mirror.type.declarations.values) {
      if (declaration is VariableMirror) {
        if (declaration.isPrivate && !includePrivate) {
          continue;
        }
        
        final name = MirrorSystem.getName(declaration.simpleName);
        final value = mirror.getField(declaration.simpleName).reflectee;
        map[name] = value;
      }
    }
    
    return map;
  }
  
  static T fromJson<T extends JsonSerializable>(Map<String, dynamic> json) {
    final type = reflectType(T) as ClassMirror;
    final constructor = type.declarations[type.simpleName]! as MethodMirror;
    
    final args = <Symbol, dynamic>{};
    
    for (final param in constructor.parameters) {
      final paramName = MirrorSystem.getName(param.simpleName);
      if (json.containsKey(paramName)) {
        args[param.simpleName] = json[paramName];
      }
    }
    
    return type.newInstance(type.simpleName, [], args).reflectee as T;
  }
}
