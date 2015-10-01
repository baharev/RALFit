! nlls_module :: a nonlinear least squares solver

module nlls_module

  implicit none

  integer, parameter :: wp = kind(1.0d0)
  integer, parameter :: long = selected_int_kind(8)
  real (kind = wp), parameter :: tenm5 = 1.0e-5
  real (kind = wp), parameter :: tenm8 = 1.0e-8
  real (kind = wp), parameter :: epsmch = epsilon(1.0_wp)
  real (kind = wp), parameter :: hundred = 100.0
  real (kind = wp), parameter :: ten = 10.0
  real (kind = wp), parameter :: point9 = 0.9
  real (kind = wp), parameter :: zero = 0.0
  real (kind = wp), parameter :: one = 1.0
  real (kind = wp), parameter :: two = 2.0
  real (kind = wp), parameter :: half = 0.5
  real (kind = wp), parameter :: sixteenth = 0.0625

  
  TYPE, PUBLIC :: NLLS_control_type
     
!   error and warning diagnostics occur on stream error 
     
     INTEGER :: error = 6

!   general output occurs on stream out

     INTEGER :: out = 6

!   the level of output required. <= 0 gives no output, = 1 gives a one-line
!    summary for every iteration, = 2 gives a summary of the inner iteration
!    for each iteration, >= 3 gives increasingly verbose (debugging) output

     INTEGER :: print_level = 0

!   any printing will start on this iteration

     INTEGER :: start_print = - 1

!   any printing will stop on this iteration

     INTEGER :: stop_print = - 1

!   the number of iterations between printing

     INTEGER :: print_gap = 1

!   the maximum number of iterations performed

     INTEGER :: maxit = 100

!   removal of the file alive_file from unit alive_unit terminates execution

     INTEGER :: alive_unit = 40
     CHARACTER ( LEN = 30 ) :: alive_file = 'ALIVE.d'

!   non-monotone <= 0 monotone strategy used, anything else non-monotone
!     strategy with this history length used

     INTEGER :: non_monotone = 1

!   specify the model used. Possible values are
!
!      0  dynamic (*not yet implemented*)
!      1  first-order (no Hessian)
!      2  second-order (exact Hessian)
!      3  barely second-order (identity Hessian)
!      4  secant second-order (sparsity-based)
!      5  secant second-order (limited-memory BFGS, with %lbfgs_vectors history)
!      6  secant second-order (limited-memory SR1, with %lbfgs_vectors history)

     INTEGER :: model = 2

!   specify the norm used. The norm is defined via ||v||^2 = v^T P v,
!    and will define the preconditioner used for iterative methods.
!    Possible values for P are
!
!     -3  user's own norm
!     -2  P = limited-memory BFGS matrix (with %lbfgs_vectors history)
!     -1  identity (= Euclidan two-norm)
!      0  automatic (*not yet implemented*)
!      1  diagonal, P = diag( max( Hessian, %min_diagonal ) )
!      2  banded, P = band( Hessian ) with semi-bandwidth %semi_bandwidth
!      3  re-ordered band, P=band(order(A)) with semi-bandwidth %semi_bandwidth
!      4  full factorization, P = Hessian, Schnabel-Eskow modification
!      5  full factorization, P = Hessian, GMPS modification (*not yet *)
!      6  incomplete factorization of Hessian, Lin-More'
!      7  incomplete factorization of Hessian, HSL_MI28
!      8  incomplete factorization of Hessian, Munskgaard (*not yet *)
!      9  expanding band of Hessian (*not yet implemented*)

     INTEGER :: norm = 1

!   specify the semi-bandwidth of the band matrix P if required

     INTEGER :: semi_bandwidth = 5

!   number of vectors used by the L-BFGS matrix P if required

     INTEGER :: lbfgs_vectors = 10

!   number of vectors used by the sparsity-based secant Hessian if required

     INTEGER :: max_dxg = 100

!   number of vectors used by the Lin-More' incomplete factorization 
!    matrix P if required

     INTEGER :: icfs_vectors = 10

!  the maximum number of fill entries within each column of the incomplete 
!  factor L computed by HSL_MI28. In general, increasing mi28_lsize improves
!  the quality of the preconditioner but increases the time to compute
!  and then apply the preconditioner. Values less than 0 are treated as 0

     INTEGER :: mi28_lsize = 10

!  the maximum number of entries within each column of the strictly lower 
!  triangular matrix R used in the computation of the preconditioner by 
!  HSL_MI28.  Rank-1 arrays of size mi28_rsize *  n are allocated internally 
!  to hold R. Thus the amount of memory used, as well as the amount of work
!  involved in computing the preconditioner, depends on mi28_rsize. Setting
!  mi28_rsize > 0 generally leads to a higher quality preconditioner than
!  using mi28_rsize = 0, and choosing mi28_rsize >= mi28_lsize is generally 
!  recommended

     INTEGER :: mi28_rsize = 10

!  which linear least squares solver should we use?
     
     INTEGER :: lls_solver
        
!   overall convergence tolerances. The iteration will terminate when the
!     norm of the gradient of the objective function is smaller than 
!       MAX( %stop_g_absolute, %stop_g_relative * norm of the initial gradient
!     or if the step is less than %stop_s

     REAL ( KIND = wp ) :: stop_g_absolute = tenm5
     REAL ( KIND = wp ) :: stop_g_relative = tenm8
     REAL ( KIND = wp ) :: stop_s = epsmch

!   try to pick a good initial trust-region radius using %advanced_start
!    iterates of a variant on the strategy of Sartenaer SISC 18(6)1990:1788-1803
     
     INTEGER :: advanced_start = 0
     
!   initial value for the trust-region radius (-ve => ||g_0||)
     
     REAL ( KIND = wp ) :: initial_radius = hundred
     
!   maximum permitted trust-region radius

     REAL ( KIND = wp ) :: maximum_radius = ten ** 8

!   a potential iterate will only be accepted if the actual decrease
!    f - f(x_new) is larger than %eta_successful times that predicted
!    by a quadratic model of the decrease. The trust-region radius will be
!    increased if this relative decrease is greater than %eta_very_successful
!    but smaller than %eta_too_successful

     REAL ( KIND = wp ) :: eta_successful = ten ** ( - 8 )
     REAL ( KIND = wp ) :: eta_very_successful = point9
     REAL ( KIND = wp ) :: eta_too_successful = two

!   on very successful iterations, the trust-region radius will be increased by
!    the factor %radius_increase, while if the iteration is unsucceful, the 
!    radius will be decreased by a factor %radius_reduce but no more than
!    %radius_reduce_max

     REAL ( KIND = wp ) :: radius_increase = two
     REAL ( KIND = wp ) :: radius_reduce = half
     REAL ( KIND = wp ) :: radius_reduce_max = sixteenth
       
!   the smallest value the onjective function may take before the problem
!    is marked as unbounded

     REAL ( KIND = wp ) :: obj_unbounded = - epsmch ** ( - 2 )

!   the maximum CPU time allowed (-ve means infinite)
     
     REAL ( KIND = wp ) :: cpu_time_limit = - one

!   the maximum elapsed clock time allowed (-ve means infinite)

     REAL ( KIND = wp ) :: clock_time_limit = - one
       
!   is the Hessian matrix of second derivatives available or is access only
!    via matrix-vector products?

     LOGICAL :: hessian_available = .TRUE.

!   use a direct (factorization) or (preconditioned) iterative method to 
!    find the search direction

     LOGICAL :: subproblem_direct = .FALSE.

!   is a retrospective strategy to be used to update the trust-region radius?

     LOGICAL :: retrospective_trust_region = .FALSE.

!   should the radius be renormalized to account for a change in preconditioner?

     LOGICAL :: renormalize_radius = .FALSE.

!   if %space_critical true, every effort will be made to use as little
!    space as possible. This may result in longer computation time
     
     LOGICAL :: space_critical = .FALSE.
       
!   if %deallocate_error_fatal is true, any array/pointer deallocation error
!     will terminate execution. Otherwise, computation will continue

     LOGICAL :: deallocate_error_fatal = .FALSE.

!  all output lines will be prefixed by %prefix(2:LEN(TRIM(%prefix))-1)
!   where %prefix contains the required string enclosed in 
!   quotes, e.g. "string" or 'string'

     CHARACTER ( LEN = 30 ) :: prefix = '""                            '
     
  END TYPE NLLS_control_type

!  - - - - - - - - - - - - - - - - - - - - - - - 
!   inform derived type with component defaults
!  - - - - - - - - - - - - - - - - - - - - - - - 

  TYPE, PUBLIC :: NLLS_inform_type
     
!  return status. See NLLS_solve for details
     
     INTEGER :: status = 0
     
!  the status of the last attempted allocation/deallocation

     INTEGER :: alloc_status = 0

!  the name of the array for which an allocation/deallocation error ocurred

     CHARACTER ( LEN = 80 ) :: bad_alloc = REPEAT( ' ', 80 )

!  the total number of iterations performed
     
     INTEGER :: iter = 0
       
!  the total number of CG iterations performed

     INTEGER :: cg_iter = 0

!  the total number of evaluations of the objection function

     INTEGER :: f_eval = 0

!  the total number of evaluations of the gradient of the objection function

     INTEGER :: g_eval = 0

!  the total number of evaluations of the Hessian of the objection function
     
     INTEGER :: h_eval = 0

!  the maximum number of factorizations in a sub-problem solve

     INTEGER :: factorization_max = 0

!  the return status from the factorization

     INTEGER :: factorization_status = 0

!   the maximum number of entries in the factors

     INTEGER ( KIND = long ) :: max_entries_factors = 0

!  the total integer workspace required for the factorization

     INTEGER :: factorization_integer = - 1

!  the total real workspace required for the factorization

     INTEGER :: factorization_real = - 1

!  the average number of factorizations per sub-problem solve

     REAL ( KIND = wp ) :: factorization_average = zero

!  the value of the objective function at the best estimate of the solution 
!   determined by NLLS_solve

     REAL ( KIND = wp ) :: obj = HUGE( one )

!  the norm of the gradient of the objective function at the best estimate 
!   of the solution determined by NLLS_solve

     REAL ( KIND = wp ) :: norm_g = HUGE( one )

!  the total CPU time spent in the package

     REAL :: cpu_total = 0.0
       
!  the CPU time spent preprocessing the problem

     REAL :: cpu_preprocess = 0.0

!  the CPU time spent analysing the required matrices prior to factorization

     REAL :: cpu_analyse = 0.0

!  the CPU time spent factorizing the required matrices
     
     REAL :: cpu_factorize = 0.0
       
!  the CPU time spent computing the search direction

     REAL :: cpu_solve = 0.0

!  the total clock time spent in the package

     REAL ( KIND = wp ) :: clock_total = 0.0
       
!  the clock time spent preprocessing the problem

     REAL ( KIND = wp ) :: clock_preprocess = 0.0
       
!  the clock time spent analysing the required matrices prior to factorization

     REAL ( KIND = wp ) :: clock_analyse = 0.0
       
!  the clock time spent factorizing the required matrices

     REAL ( KIND = wp ) :: clock_factorize = 0.0
     
!  the clock time spent computing the search direction

     REAL ( KIND = wp ) :: clock_solve = 0.0

  END TYPE NLLS_inform_type

contains


  SUBROUTINE RAL_NLLS( n, m, X, Work_int, len_work_int,                     &
                       Work_real, len_work_real,                            &
                       eval_F, eval_J,                                      &
                       status, options )
    
!  -----------------------------------------------------------------------------
!  RAL_NLLS, a fortran subroutine for finding a first-order critical
!   point (most likely, a local minimizer) of the nonlinear least-squares 
!   objective function 1/2 ||F(x)||_2^2.

!  Authors: RAL NA Group (Iain Duff, Nick Gould, Jonathan Hogg, Tyrone Rees, 
!                         Jennifer Scott)
!  -----------------------------------------------------------------------------

!   Dummy arguments

    USE ISO_FORTRAN_ENV
    INTEGER( int32 ), INTENT( IN ) :: n, m, len_work_int, len_work_real
    REAL( wp ), DIMENSION( n ), INTENT( INOUT ) :: X
    INTEGER( int32), INTENT( IN ) :: Work_int(len_work_int)
    REAL( wp ), INTENT( IN ) :: Work_real(len_work_real)
    TYPE( NLLS_inform_type ), INTENT( OUT ) :: status
    TYPE( NLLS_control_type ), INTENT( IN ) :: options

!  Interface blocks (e.g.)

    INTERFACE
       SUBROUTINE eval_F( status, X, f )
         USE ISO_FORTRAN_ENV
         
         INTEGER ( int32 ), INTENT( OUT ) :: status
         REAL ( real64 ), DIMENSION( : ),INTENT( OUT ) :: f
         REAL ( real64 ), DIMENSION( : ),INTENT( IN ) :: X
         
       END SUBROUTINE eval_F
    END INTERFACE

    INTERFACE
       SUBROUTINE eval_J( status, X, J )
         USE ISO_FORTRAN_ENV

         INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )
         INTEGER ( int32 ), INTENT( OUT ) :: status
         REAL ( real64 ), DIMENSION( : ),INTENT( IN ) :: X
         REAL ( real64 ), DIMENSION( : , : ),INTENT( OUT ) :: J
       END SUBROUTINE eval_J
    END INTERFACE
    
    integer :: jstatus=0, fstatus=0, slls_status, fb_status
    integer :: i
    real(wp), DIMENSION(m,n) :: J, Jnew
    real(wp), DIMENSION(m) :: f, fnew
    real(wp), DIMENSION(n) :: g, d_sd, d_gn, d, ghat, Xnew
    real(wp) :: alpha, beta, Delta, rho
    

    if ( options%print_level >= 3 )  write( options%out , 2000 ) 


    Delta = options%initial_radius
    
    call eval_J(jstatus, X, J)
    if (jstatus > 0) write( options%out, 2010) jstatus
    call eval_F(fstatus, X, f)
    if (fstatus > 0) write( options%out, 2020) fstatus

    g = - matmul(transpose(J),f);

    main_loop: do i = 1,options%maxit
       
       alpha = norm2(g)**2 / norm2( matmul(J,g) )**2
       
       d_sd = alpha * g;
       call solve_LLS(J,f,n,m,options%lls_solver,d_gn,slls_status)
       
       if (norm2(d_gn) <= Delta) then
          d = d_gn
       else if (norm2( alpha * d_sd ) >= Delta) then
          d = (Delta / norm2(d_sd) ) * d_sd
       else
          ghat = d_gn - alpha * d_sd
          call findbeta(d_sd,ghat,alpha,beta,fb_status)
          d = alpha * d_sd + beta * ghat
       end if

       ! Test convergence
       if (norm2(d) <= options%stop_g_relative * norm2(X)) then
          if (options%print_level > 0 ) write(options%out,2030) i
          return
       else
          Xnew = X + d;
          call eval_J(jstatus, Xnew, Jnew)
          if (jstatus > 0) write( options%out, 2010) jstatus
          call eval_F(fstatus, Xnew, fnew)
          if (fstatus > 0) write( options%out, 2020) fstatus

          rho = ( norm2(f)**2 - norm2(fnew)**2 ) / &
                ( norm2(f)**2 - norm2(f - matmul(J,d))**2)

          if (rho > 0) then
             X = Xnew;
             J = Jnew;
             f = fnew;
             g = - matmul(transpose(J),f);
          end if
          
          ! todo :: finer-grained changes (successful, too_successful...)
          if (rho > options%eta_very_successful) then
             Delta = max(Delta, 3.0 * norm2(d) )
          else
             Delta = Delta / 2.0
          end if

       end if

    end do main_loop

    if (options%print_level > 0 ) write(options%out,2040) 

    RETURN

! Non-executable statements

2000 FORMAT(/,'* Running RAL_NLLS *')
2010 FORMAT('Error code from eval_J, status = ',I6)
2020 FORMAT('Error code from eval_J, status = ',I6)
2030 FORMAT('RAL_NLLS converged at iteration ',I6)
2040 FORMAT(/,'RAL_NLLS failed to converge in the allowed number of iterations')
!  End of subroutine RAL_NLLS

     END SUBROUTINE RAL_NLLS

     SUBROUTINE solve_LLS(J,f,n,m,method,d_gn,status)
       
!  -----------------------------------------------------------------
!  solve_LLS, a subroutine to solve a linear least squares problem
!  -----------------------------------------------------------------

       REAL(wp), DIMENSION(:,:), INTENT(INOUT) :: J
       REAL(wp), DIMENSION(:), INTENT(IN) :: f
       INTEGER, INTENT(IN) :: method, n, m
       REAL(wp), DIMENSION(:), INTENT(OUT) :: d_gn
       INTEGER, INTENT(OUT) :: status

       character(1) :: trans = 'N'
       integer :: nrhs = 1, lwork, lda, ldb
       real(wp), allocatable :: temp(:), work(:)
       
       integer :: i

       lda = n
       ldb = max(m,n)
       allocate(temp(max(m,n)))
       temp(1:n) = f(1:n)
       lwork = max(1, min(m,n) + max(min(m,n), nrhs)*4)
       allocate(work(lwork))
       
       call dgels(trans, n, m, nrhs, J, lda, temp, ldb, work, lwork, status)

       d_gn = -temp(1:n)
              
     END SUBROUTINE solve_LLS
     
     SUBROUTINE findbeta(d_sd,ghat,alpha,beta,status)

!  -----------------------------------------------------------------
!  findbeta, a subroutine to find the optimal beta such that 
!   || d || = Delta
!  -----------------------------------------------------------------

     real(wp), dimension(:), intent(in) :: d_sd, ghat
     real(wp), intent(in) :: alpha
     real(wp), intent(out) :: beta
     integer, intent(out) :: status
     
     real(wp) :: a, b, c, discriminant

     a = norm2(ghat)**2
     b = 2.0 * alpha * dot_product( ghat, d_sd)
     c = ( alpha * norm2( d_sd ) )**2 - 1
     
     discriminant = b**2 - 4 * a * c
     if ( discriminant < 0) then
        status = 1
        return
     else
        beta = (-b + sqrt(discriminant)) / (2.0 * a)
     end if

     END SUBROUTINE findbeta

     
     SUBROUTINE eval_F( status, X, f )

!  -------------------------------------------------------------------
!  eval_F, a subroutine for evaluating the function f at a point X
!  -------------------------------------------------------------------

       USE ISO_FORTRAN_ENV

       INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )
       INTEGER ( int32 ), INTENT( OUT ) :: status
       REAL ( real64 ), DIMENSION( : ),INTENT( OUT ) :: f
       REAL ( real64 ), DIMENSION( : ),INTENT( IN )  :: X

! let's use Powell's function for now....
       f(1) = X(1) + 10.0 * X(2)
       f(2) = sqrt(5.0) * (X(3) - X(4))
       f(3) = ( X(2) - 2.0 * X(3) )**2
       f(4) = sqrt(10.0) * ( X(1) - X(4) )**2
       
! end of subroutine eval_F
       
     END SUBROUTINE eval_F

     SUBROUTINE eval_J( status, X, J )

!  -------------------------------------------------------------------
!  eval_J, a subroutine for evaluating the Jacobian J at a point X
!  -------------------------------------------------------------------

       USE ISO_FORTRAN_ENV

       INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )
       INTEGER ( int32 ), INTENT( OUT ) :: status
       REAL ( real64 ), DIMENSION( : , : ),INTENT( OUT ) :: J
       REAL ( real64 ), DIMENSION( : ),INTENT( IN ) :: X

! end of subroutine eval_J

       ! initialize to zeros...
       J(1:4,1:4) = 0.0
       
       ! enter non-zeros values
       J(1,1) = 1.0
       J(1,2) = 10.0
       J(2,3) = sqrt(5.0)
       J(2,4) = -sqrt(5.0)
       J(3,2) = 2.0 * (X(2) - 2.0 * X(3))
       J(3,3) = -4.0 * (X(2) - 2.0 * X(3)) 
       J(4,1) = sqrt(10.0) * 2.0 * (X(1) - X(4))
       J(4,4) = - sqrt(10.0) * 2.0 * (X(1) - X(4))

     END SUBROUTINE eval_J

end module nlls_module
