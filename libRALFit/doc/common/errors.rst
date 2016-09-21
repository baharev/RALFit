Possible values are:

.. list-table::

    * - -1
      -  Maximum number of iterations reached without convergence.
    * - -2
      -  Error from evaluating a function/Jacobian/Hessian.
    * - -3
      -  Unsupported choice of model.
    * - -4
      -  Error return from an external routine.
    * - -5
      -  Unsupported choice of method.
    * - -6
      -  Allocation error.
    * - -7
      -  Maximum number of reductions of the trust radius reached.
    * - -8
      -  No progress being made in the solution.
    * - -9
      -  **n** :math:`>` **m**.
    * - -10
      -  Unsupported trust region update strategy.
    * - -11
      -  Unable to valid step when solving trust region subproblem.
    * - -12
      -  Unsupported scaling method.
    * - -13
      -  Error accessing pre-allocated workspace.
    * - -101
      -  Unsupported model in dogleg (``nlls_method = 1``).
    * - -201
      -  All eigenvalues are imaginary (``nlls_method=2``).
    * - -202
      -  Matrix with odd number of columns sent to ``max_eig`` subroutine (``nlls_method=2``).
    * - -301
      - ``nlls_options\ct more_sorensen_max_its`` is exceeded in ``more_sorensen`` subroutine (``nlls_method=3``).
    * - -302
      - Too many shifts taken in ``more_sorensen`` subroutine (``nlls_method=3``).
    * - -303
      -  No progress being made in ``more_sorensen`` subroutine (``nlls_method=3``).
    * - -401
      - ``nlls_options``\ct ``model = 4`` selected, but ``nlls_options``\ct ``exact_second_derivatives`` is set to ``false``. 
    * - -501
      - ``nlls_options``\ct ``type_of_method = 2`` selected, but ``nlls_options``\ct ``type_of_method`` is not equal to {\tt 4}.