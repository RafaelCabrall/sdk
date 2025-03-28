// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/string_scanner.dart'
    show StringScanner;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/kernel.dart'
    show Component, Library, Procedure, DartType, TypeParameter;

import '../base/compiler_context.dart' show CompilerContext;
import '../base/incremental_compiler.dart' show IncrementalCompiler;
import '../base/incremental_serializer.dart' show IncrementalSerializer;
import '../base/processed_options.dart' show ProcessedOptions;
import 'compiler_options.dart' show CompilerOptions;

export '../base/incremental_serializer.dart' show IncrementalSerializer;

// Coverage-ignore(suite): Not run.
abstract class IncrementalKernelGenerator {
  factory IncrementalKernelGenerator(
      CompilerOptions options, List<Uri> entryPoints,
      [Uri? initializeFromDillUri,
      bool? outlineOnly,
      IncrementalSerializer? incrementalSerializer]) {
    return new IncrementalCompiler(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: entryPoints)),
        initializeFromDillUri,
        outlineOnly,
        incrementalSerializer);
  }

  /// Initialize the incremental compiler from a component.
  ///
  /// Notice that the component has to include the platform, and that no other
  /// platform will be loaded.
  factory IncrementalKernelGenerator.fromComponent(
      CompilerOptions options, List<Uri> entryPoints, Component? component,
      [bool? outlineOnly, IncrementalSerializer? incrementalSerializer]) {
    return new IncrementalCompiler.fromComponent(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: entryPoints)),
        component,
        outlineOnly,
        incrementalSerializer);
  }

  /// Initialize the incremental compiler specifically for expression
  /// compilation where the dill is external and we cannot expect to have access
  /// to the sources.
  ///
  /// The resulting incremental compiler allows for expression compilation,
  /// but not for general compilation. Note that computeDelta will have to be
  /// called once to setup properly though.
  ///
  /// Notice that the component has to include the platform, and that no other
  /// platform will be loaded.
  factory IncrementalKernelGenerator.forExpressionCompilationOnly(
      CompilerOptions options, List<Uri> entryPoints, Component component) {
    return new IncrementalCompiler.forExpressionCompilationOnly(
        new CompilerContext(
            new ProcessedOptions(options: options, inputs: entryPoints)),
        component);
  }

  /// Returns an [IncrementalCompilerResult] with the component whose libraries
  /// are the recompiled libraries, or - in the case of [fullComponent] - a full
  /// Component.
  Future<IncrementalCompilerResult> computeDelta(
      {List<Uri>? entryPoints,
      bool fullComponent = false,
      bool trackNeededDillLibraries = false});

  /// Remove the file associated with the given file [uri] from the set of
  /// valid files.  This guarantees that those files will be re-read on the
  /// next call to [computeDelta]).
  void invalidate(Uri uri);

  /// Invalidate all libraries that were build from source.
  ///
  /// This is equivalent to a number of calls to [invalidate]: One for each URI
  /// that happens to have been read from source.
  /// Said another way, this invalidates everything not loaded from dill
  /// (at startup) or via [setModulesToLoadOnNextComputeDelta].
  void invalidateAllSources();

  /// Set the given [components] as components to load on the next iteration
  /// of [computeDelta].
  ///
  /// If specified, all libraries not compiled from source and not included in
  /// these components will be invalidated and the libraries inside these
  /// components will be loaded instead.
  ///
  /// Useful for, for instance, modular compilation, where modules
  /// (created externally) via this functionality can be added, changed or
  /// removed.
  void setModulesToLoadOnNextComputeDelta(List<Component> components);

  /// Compile [expression] as an [Expression]. A function returning that
  /// expression is compiled.
  ///
  /// [expression] may use the variables supplied in [definitions] as free
  /// variables and [typeDefinitions] as free type parameters. These will become
  /// required parameters to the compiled function. All elements of
  /// [definitions] and [typeDefinitions] will become parameters/type
  /// parameters, whether or not they appear free in [expression]. The type
  /// parameters should have a null parent pointer.
  ///
  /// [libraryUri] must refer to either a previously compiled library.
  /// [className] may optionally refer to a class within such library to use for
  /// the scope of the expression. In that case, [isStatic] indicates whether
  /// the scope can access this [IncrementalKernelGenerator].
  ///
  /// It is illegal to use "await" in [expression] and the compiled function
  /// will always be synchronous.
  ///
  /// [computeDelta] must have been called at least once prior.
  ///
  /// [compileExpression] will return [null] if the library or class for
  /// [enclosingNode] could not be found. Otherwise, errors are reported in the
  /// normal way.
  Future<Procedure?> compileExpression(
      String expression,
      Map<String, DartType> definitions,
      List<TypeParameter> typeDefinitions,
      String syntheticProcedureName,
      Uri libraryUri,
      {String? className,
      String? methodName,
      int offset = -1,
      String? scriptUri,
      bool isStatic = false});

  /// Sets experimental features.
  ///
  /// This is currently only meant for testing purposes.
  void setExperimentalFeaturesForTesting(Set<String> features);
}

// Coverage-ignore(suite): Not run.
bool isLegalIdentifier(String identifier) {
  return StringScanner.isLegalIdentifier(identifier);
}

class IncrementalCompilerResult {
  final Component component;
  final ClassHierarchy classHierarchy;
  final CoreTypes coreTypes;
  final Set<Library>? neededDillLibraries;

  IncrementalCompilerResult(this.component,
      {required this.classHierarchy,
      required this.coreTypes,
      this.neededDillLibraries});
}
