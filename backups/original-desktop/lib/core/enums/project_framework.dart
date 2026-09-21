enum ProjectFramework {
  flutter,
  react,
  nextjs,
  vite,
  nodejs,
  python,
  fastapi,
  django,
  java,
  spring,
  android,
  dotnet,
  csharp,
  cpp,
  go,
  rust,
  electron,
  unknown,
}

extension ProjectFrameworkExtension on ProjectFramework {
  String get label {
    switch (this) {
      case ProjectFramework.flutter:
        return 'Flutter';
      case ProjectFramework.react:
        return 'React';
      case ProjectFramework.nextjs:
        return 'Next.js';
      case ProjectFramework.vite:
        return 'Vite';
      case ProjectFramework.nodejs:
        return 'Node.js';
      case ProjectFramework.python:
        return 'Python';
      case ProjectFramework.fastapi:
        return 'FastAPI';
      case ProjectFramework.django:
        return 'Django';
      case ProjectFramework.java:
        return 'Java';
      case ProjectFramework.spring:
        return 'Spring';
      case ProjectFramework.android:
        return 'Android';
      case ProjectFramework.dotnet:
        return '.NET';
      case ProjectFramework.csharp:
        return 'C#';
      case ProjectFramework.cpp:
        return 'C++';
      case ProjectFramework.go:
        return 'Go';
      case ProjectFramework.rust:
        return 'Rust';
      case ProjectFramework.electron:
        return 'Electron';
      case ProjectFramework.unknown:
        return 'Unknown';
    }
  }

  List<String> get markerFiles {
    switch (this) {
      case ProjectFramework.flutter:
        return ['pubspec.yaml'];
      case ProjectFramework.react:
      case ProjectFramework.nextjs:
      case ProjectFramework.vite:
      case ProjectFramework.nodejs:
        return ['package.json'];
      case ProjectFramework.python:
      case ProjectFramework.fastapi:
      case ProjectFramework.django:
        return ['pyproject.toml', 'requirements.txt', 'setup.py'];
      case ProjectFramework.java:
      case ProjectFramework.spring:
        return ['pom.xml', 'build.gradle', 'settings.gradle'];
      case ProjectFramework.android:
        return ['build.gradle', 'settings.gradle', 'build.gradle.kts'];
      case ProjectFramework.dotnet:
      case ProjectFramework.csharp:
        return ['*.csproj', '*.sln'];
      case ProjectFramework.cpp:
        return ['CMakeLists.txt', 'Makefile'];
      case ProjectFramework.go:
        return ['go.mod'];
      case ProjectFramework.rust:
        return ['Cargo.toml'];
      case ProjectFramework.electron:
        return ['package.json'];
      case ProjectFramework.unknown:
        return [];
    }
  }
}