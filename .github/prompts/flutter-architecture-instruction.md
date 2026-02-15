# GitHub Copilot Instructions - Flutter Super Architecture

## CONTEXT AND ARCHITECTURE RULES

We are an expert Flutter & Dart Architect. Your goal is to generate code that is maintainable, testable, and strictly follows SOLID principles and Clean Architecture.

## ARCHITECTURE STACK

- **Clean Architecture** with 3 layers: Domain, Data, Presentation
- **BLoC Pattern** for state management (bloc + cubit)
- **SOLID Principles** strictly enforced
- **GRASP Patterns** for responsibility assignment
- **TDD Approach** with high test coverage
- **Functional Programming** with Either/Result patterns

## PROJECT STRUCTURE

.
├── application
│ ├── factory
│ └── services
├── core
│ ├── config
│ ├── database
│ ├── error
│ ├── network
│ └── utils
│ └── interface
├── domain
│ ├── entities
│ ├── repositories
│ └── use_case
├── feature
│ ├── clocking
│ │ ├── domain
│ │ │ ├── entities
│ │ │ ├── repositories
│ │ │ └── use_case
│ │ ├── infrastructure
│ │ │ └── repositories
│ │ └── ui
│ │ ├── bloc
│ │ ├── mobile
│ │ │ └── widgets
│ │ └── web
│ ├── sondage
│ │ ├── domain
│ │ │ ├── entities
│ │ │ ├── repositories
│ │ │ └── use_case
│ │ ├── infrastructure
│ │ │ └── repositories
│ │ └── ui
│ │ ├── bloc
│ │ ├── mobile
│ │ │ └── widgets
│ │ └── web
│ └── team
│ ├── domain
│ │ ├── entities
│ │ ├── repositories
│ │ └── use_case
│ ├── infrastructure
│ │ └── repositories
│ └── ui
│ ├── bloc
│ ├── helper
│ ├── mobile
│ │ └── widgets
│ ├── web
│ │ └── widgets
│ └── widgets
├── infrastructure
│ ├── model
│ │ └── adapter
│ └── repository_impl
│ ├── auth
│ ├── network
│ └── theme
├── languages
│ └── l10n
├── theme
│ └── extensions
│ └── color_scheme
└── ui
├── bloc
│ ├── auth_bloc
│ └── navigation_bloc
├── mobile
│ └── widgets
│ ├── home
│ ├── login
│ └── settings
├── web
│ ├── login
│ ├── settings
│ └── widgets
│ └── home
└── widgets
├── splash_screen
└── theme_config
└── bloc
└── theme

## TIPI DI WIDGET - PRIORITÀ

1. **StatelessWidget**: PRIMA SCELTA SEMPRE
2. **StatefulWidget**: SOLO se necessario per stato interno locale
3. **StatelessWidget + BlocBuilder**: Per stato condiviso/complesso
4. **Consumer/Package:provider/provider**: Alternative a BLoC se progetto già usa Provider
5. **Naming**: Use `PascalCase` for classes and `camelCase` for variables/methods.
6. **State Management**: Default to `flutter_bloc`. Keep states immutable using `equatable`.

## PERFORMANCE - REGOLE STRETTE

- **NO** setState() in alberi widget grandi
- **SI** const constructor per widget statici
- **NO** rebuild inutili - usare const dove possibile
- **SI** Key appropriati (ValueKey, ObjectKey)
- **NO** funzioni anonime in build() per event handlers

## SCHEMA DECISIONALE STATO

1. **Stato Locale (widget-specific)**
   → StatefulWidget (se semplice)
   → StatelessWidget + ValueNotifier (se medio)

2. **Stato Condiviso (multi-widget)**
   → StatelessWidget + BlocBuilder (PRIMA SCELTA)
   → StatelessWidget + Consumer/Provider
   → InheritedWidget (solo casi specifici)

3. **Stato Globale (app-wide)**
   → Bloc/Cubit con BlocProvider a root
   → Provider con MultiProvider

## Coding Style

- Always use `final` for variables that don't change.
- Use required named parameters for constructors.
- Add documentation comments (`///`) for complex business logic.
