# Before any changes

- Read **ALL** the docs in docs/ folder
- If requirements are ambiguous, ask first.
- If there is a better solution than the requested one, explain it before implementing.

# During any changes

- Follow the SOLID princles:
  
  S - don't create classes that for example both manage the sons and authors.
  O - classes should be created to be easy extended/modified from outside if some new feature will be required instead of modifying class.and making it more complex.
  L - child classes should not break the app if they will be used instead of parent classes.
  I - create as simple as possible interfaces so each part of app will depend and have access to only methods that it really requires.
  D - Make low level classes depend on top level.

- Make any user-seeing client-side text localized.
- Ensure you added collecting breadcrumbs using [ErrorReporter.addBreadcrumb](lib/errors/error_reporter/error_reporter.dart:6) if needed.
- Write tests for new code if it's important. For example don't write tests for button color.

# After any changes
- Run dart linter and DCM to avoid common issues:

  ```bash
  dart analyze .
  dcm analyze .
  ```

- Run tests to verify that nothing are broked:

  ```bash
  flutter test .
  ```

- If any issues found then fix them and repeat `After any changes` steps.
- **[Only after any other command and changes]** Format the code:

  ```bash
  dart format .
  ```