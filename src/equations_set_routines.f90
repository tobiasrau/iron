!> \file
!> \author Chris Bradley
!> \brief This module handles all equations set routines.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand, the University of Oxford, Oxford, United
!> Kingdom and King's College, London, United Kingdom. Portions created
!> by the University of Auckland, the University of Oxford and King's
!> College, London are Copyright (C) 2007-2010 by the University of
!> Auckland, the University of Oxford and King's College, London.
!> All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> This module handles all equations set routines.
MODULE EQUATIONS_SET_ROUTINES

  USE BASE_ROUTINES
  USE BASIS_ROUTINES
  USE BIOELECTRIC_ROUTINES
  USE BOUNDARY_CONDITIONS_ROUTINES
  USE CLASSICAL_FIELD_ROUTINES
  USE CMISS_MPI
  USE COMP_ENVIRONMENT
  USE CONSTANTS
  USE COORDINATE_ROUTINES
  USE FIELD_ROUTINES
  USE FITTING_ROUTINES
  USE DISTRIBUTED_MATRIX_VECTOR
  USE DOMAIN_MAPPINGS
  USE ELASTICITY_ROUTINES
  USE EQUATIONS_ROUTINES
  USE EQUATIONS_SET_CONSTANTS
  USE EQUATIONS_MATRICES_ROUTINES
  USE FIELD_ROUTINES
  USE FLUID_MECHANICS_ROUTINES
  USE INPUT_OUTPUT
  USE ISO_VARYING_STRING
  USE KINDS
  USE LISTS
  USE MATRIX_VECTOR
  USE MONODOMAIN_EQUATIONS_ROUTINES
#ifndef NOMPIMOD
  USE MPI
#endif
  USE MULTI_PHYSICS_ROUTINES
  USE NODE_ROUTINES
  USE PRINT_TYPES_ROUTINES
  USE STRINGS
  USE TIMER
  USE TYPES

#include "macros.h"  

  IMPLICIT NONE

#ifdef NOMPIMOD
#include "mpif.h"
#endif

  PRIVATE

  !Module parameters

  !Module types

  !Module variables

  !Interfaces

  PUBLIC EQUATIONS_SET_ANALYTIC_CREATE_START,EQUATIONS_SET_ANALYTIC_CREATE_FINISH

  PUBLIC EQUATIONS_SET_ANALYTIC_DESTROY

  PUBLIC EQUATIONS_SET_ANALYTIC_EVALUATE

  PUBLIC EQUATIONS_SET_ANALYTIC_TIME_GET,EQUATIONS_SET_ANALYTIC_TIME_SET
  
  PUBLIC EQUATIONS_SET_ASSEMBLE
  
  PUBLIC EQUATIONS_SET_BACKSUBSTITUTE,EQUATIONS_SET_NONLINEAR_RHS_UPDATE
  
  PUBLIC EQUATIONS_SET_BOUNDARY_CONDITIONS_ANALYTIC

  PUBLIC EQUATIONS_SET_CREATE_START,EQUATIONS_SET_CREATE_FINISH

  PUBLIC EQUATIONS_SET_DESTROY

  PUBLIC EQUATIONS_SETS_FINALISE,EQUATIONS_SETS_INITIALISE

  PUBLIC EQUATIONS_SET_EQUATIONS_CREATE_FINISH,EQUATIONS_SET_EQUATIONS_CREATE_START

  PUBLIC EQUATIONS_SET_EQUATIONS_DESTROY
  
  PUBLIC EQUATIONS_SET_MATERIALS_CREATE_START,EQUATIONS_SET_MATERIALS_CREATE_FINISH

  PUBLIC EQUATIONS_SET_MATERIALS_DESTROY
  
  PUBLIC EQUATIONS_SET_DEPENDENT_CREATE_START,EQUATIONS_SET_DEPENDENT_CREATE_FINISH

  PUBLIC EQUATIONS_SET_DEPENDENT_DESTROY

  PUBLIC EquationsSet_DerivedCreateStart,EquationsSet_DerivedCreateFinish

  PUBLIC EquationsSet_DerivedDestroy
  
  PUBLIC EQUATIONS_SET_INDEPENDENT_CREATE_START,EQUATIONS_SET_INDEPENDENT_CREATE_FINISH

  PUBLIC EQUATIONS_SET_INDEPENDENT_DESTROY
  
  PUBLIC EQUATIONS_SET_JACOBIAN_EVALUATE,EQUATIONS_SET_RESIDUAL_EVALUATE
  
  PUBLIC EQUATIONS_SET_SOLUTION_METHOD_GET,EQUATIONS_SET_SOLUTION_METHOD_SET
  
  PUBLIC EQUATIONS_SET_SOURCE_CREATE_START,EQUATIONS_SET_SOURCE_CREATE_FINISH

  PUBLIC EQUATIONS_SET_SOURCE_DESTROY

  PUBLIC EquationsSet_SpecificationGet,EquationsSet_SpecificationSizeGet

  PUBLIC EquationsSet_StrainInterpolateXi

  PUBLIC EquationsSet_DerivedVariableCalculate,EquationsSet_DerivedVariableSet

  PUBLIC EQUATIONS_SET_USER_NUMBER_FIND
  
  PUBLIC EQUATIONS_SET_LOAD_INCREMENT_APPLY
  
  PUBLIC EQUATIONS_SET_ANALYTIC_USER_PARAM_SET,EQUATIONS_SET_ANALYTIC_USER_PARAM_GET

CONTAINS

  !
  !================================================================================================================================
  !
      
  !>Finish the creation of a analytic solution for equations set. \see OPENCMISS::CMISSEquationsSetAnalyticCreateFinish
  SUBROUTINE EQUATIONS_SET_ANALYTIC_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to create the analytic for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: ANALYTIC_FIELD

    ENTERS("EQUATIONS_SET_ANALYTIC_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%ANALYTIC)) THEN
        IF(EQUATIONS_SET%ANALYTIC%ANALYTIC_FINISHED) THEN
          CALL FlagError("Equations set analytic has already been finished.",ERR,ERROR,*999)
        ELSE
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_ANALYTIC_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
          ANALYTIC_FIELD=>EQUATIONS_SET%ANALYTIC%ANALYTIC_FIELD
          IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
            EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=ANALYTIC_FIELD%USER_NUMBER
            EQUATIONS_SET_SETUP_INFO%FIELD=>ANALYTIC_FIELD
          ENDIF
          !Finish the equations set specific analytic setup
          CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finish the analytic creation
          EQUATIONS_SET%ANALYTIC%ANALYTIC_FINISHED=.TRUE.
        ENDIF
      ELSE
        CALL FlagError("The equations set analytic is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_CREATE_FINISH",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Start the creation of a analytic solution for a equations set. \see OPENCMISS::CMISSEquationsSetAnalyticCreateStart
  SUBROUTINE EQUATIONS_SET_ANALYTIC_CREATE_START(EQUATIONS_SET,ANALYTIC_FUNCTION_TYPE,ANALYTIC_FIELD_USER_NUMBER,ANALYTIC_FIELD, &
    & ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to start the creation of an analytic for.
    INTEGER(INTG), INTENT(IN) :: ANALYTIC_FUNCTION_TYPE !<The analytic function type to setup \see EQUATIONS_SET_CONSTANTS_AnalyticFunctionTypes,EQUATIONS_SET_CONSTANTS
    INTEGER(INTG), INTENT(IN) :: ANALYTIC_FIELD_USER_NUMBER !<The user specified analytic field number
    TYPE(FIELD_TYPE), POINTER :: ANALYTIC_FIELD !<If associated on entry, a pointer to the user created analytic field which has the same user number as the specified analytic field user number. If not associated on entry, on exit, a pointer to the created analytic field for the equations set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: FIELD,GEOMETRIC_FIELD
    TYPE(REGION_TYPE), POINTER :: REGION,ANALYTIC_FIELD_REGION
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    ENTERS("EQUATIONS_SET_ANALYTIC_CREATE_START",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%ANALYTIC)) THEN
        CALL FlagError("The equations set analytic is already associated.",ERR,ERROR,*998)
      ELSE
        REGION=>EQUATIONS_SET%REGION
        IF(ASSOCIATED(REGION)) THEN
          IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
            !Check the analytic field has been finished
            IF(ANALYTIC_FIELD%FIELD_FINISHED) THEN
              !Check the user numbers match
              IF(ANALYTIC_FIELD_USER_NUMBER/=ANALYTIC_FIELD%USER_NUMBER) THEN
                LOCAL_ERROR="The specified analytic field user number of "// &
                  & TRIM(NUMBER_TO_VSTRING(ANALYTIC_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                  & " does not match the user number of the specified analytic field of "// &
                  & TRIM(NUMBER_TO_VSTRING(ANALYTIC_FIELD%USER_NUMBER,"*",ERR,ERROR))//"."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
              ANALYTIC_FIELD_REGION=>ANALYTIC_FIELD%REGION
              IF(ASSOCIATED(ANALYTIC_FIELD_REGION)) THEN                
                !Check the field is defined on the same region as the equations set
                IF(ANALYTIC_FIELD_REGION%USER_NUMBER/=REGION%USER_NUMBER) THEN
                  LOCAL_ERROR="Invalid region setup. The specified analytic field has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(ANALYTIC_FIELD_REGION%USER_NUMBER,"*",ERR,ERROR))// &
                    & " and the specified equations set has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
                !Check the specified analytic field has the same decomposition as the geometric field
                GEOMETRIC_FIELD=>EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD
                IF(ASSOCIATED(GEOMETRIC_FIELD)) THEN
                  IF(.NOT.ASSOCIATED(GEOMETRIC_FIELD%DECOMPOSITION,ANALYTIC_FIELD%DECOMPOSITION)) THEN
                    CALL FlagError("The specified analytic field does not have the same decomposition as the geometric "// &
                      & "field for the specified equations set.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("The geometric field is not associated for the specified equations set.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("The specified analytic field region is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("The specified analytic field has not been finished.",ERR,ERROR,*999)
            ENDIF
          ELSE
            !Check the user number has not already been used for a field in this region.
            NULLIFY(FIELD)
            CALL FIELD_USER_NUMBER_FIND(ANALYTIC_FIELD_USER_NUMBER,REGION,FIELD,ERR,ERROR,*999)
            IF(ASSOCIATED(FIELD)) THEN
              LOCAL_ERROR="The specified analytic field user number of "// &
                & TRIM(NUMBER_TO_VSTRING(ANALYTIC_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                & "has already been used to create a field on region number "// &
                & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ENDIF
          !Initialise the equations set analytic
          CALL EQUATIONS_SET_ANALYTIC_INITIALISE(EQUATIONS_SET,ERR,ERROR,*999)
          IF(.NOT.ASSOCIATED(ANALYTIC_FIELD)) EQUATIONS_SET%ANALYTIC%ANALYTIC_FIELD_AUTO_CREATED=.TRUE.
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_ANALYTIC_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
          EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=ANALYTIC_FIELD_USER_NUMBER
          EQUATIONS_SET_SETUP_INFO%FIELD=>ANALYTIC_FIELD
          EQUATIONS_SET_SETUP_INFO%ANALYTIC_FUNCTION_TYPE=ANALYTIC_FUNCTION_TYPE
          !Start the equations set specific analytic setup
          CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Set pointers
          IF(EQUATIONS_SET%ANALYTIC%ANALYTIC_FIELD_AUTO_CREATED) THEN
            ANALYTIC_FIELD=>EQUATIONS_SET%ANALYTIC%ANALYTIC_FIELD
          ELSE
            EQUATIONS_SET%ANALYTIC%ANALYTIC_FIELD=>ANALYTIC_FIELD
          ENDIF
        ELSE
          CALL FlagError("Equations set region is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_CREATE_START")
    RETURN
999 CALL EQUATIONS_SET_ANALYTIC_FINALISE(EQUATIONS_SET%ANALYTIC,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_CREATE_START",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_CREATE_START
  
  !
  !================================================================================================================================
  !

  !>Destroy the analytic solution for an equations set. \see OPENCMISS::CMISSEquationsSetAnalyticDestroy
  SUBROUTINE EQUATIONS_SET_ANALYTIC_DESTROY(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to destroy the analytic solutins for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_ANALYTIC_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%ANALYTIC)) THEN        
        CALL EQUATIONS_SET_ANALYTIC_FINALISE(EQUATIONS_SET%ANALYTIC,ERR,ERROR,*999)
      ELSE
        CALL FlagError("Equations set analytic is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_DESTROY")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_DESTROY

  !
  !================================================================================================================================
  !

  !>Evaluates the current analytic solution for an equations set. \see OPENCMISS::CMISSEquationsSetAnalyticEvaluate
  SUBROUTINE EQUATIONS_SET_ANALYTIC_EVALUATE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to evaluate the current analytic solutins for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: component_idx,derivative_idx,element_idx,Gauss_idx,GLOBAL_DERIV_INDEX,local_ny,node_idx, &
      & NUMBER_OF_ANALYTIC_COMPONENTS,NUMBER_OF_DIMENSIONS,variable_idx, &
      & variable_type,version_idx
    REAL(DP) :: NORMAL(3),POSITION(3),TANGENTS(3,3),VALUE
    REAL(DP) :: ANALYTIC_DUMMY_VALUES(1)=0.0_DP
    REAL(DP) :: MATERIALS_DUMMY_VALUES(1)=0.0_DP
    LOGICAL :: reverseNormal=.FALSE.
    TYPE(BASIS_TYPE), POINTER :: BASIS
    TYPE(DOMAIN_TYPE), POINTER :: DOMAIN
    TYPE(DOMAIN_ELEMENTS_TYPE), POINTER :: DOMAIN_ELEMENTS
    TYPE(DOMAIN_NODES_TYPE), POINTER :: DOMAIN_NODES
    TYPE(FIELD_TYPE), POINTER :: ANALYTIC_FIELD,DEPENDENT_FIELD,GEOMETRIC_FIELD,MATERIALS_FIELD
    TYPE(FIELD_INTERPOLATION_PARAMETERS_PTR_TYPE), POINTER :: ANALYTIC_INTERP_PARAMETERS(:),GEOMETRIC_INTERP_PARAMETERS(:), &
      & MATERIALS_INTERP_PARAMETERS(:)
    TYPE(FIELD_INTERPOLATED_POINT_PTR_TYPE), POINTER :: ANALYTIC_INTERP_POINT(:),GEOMETRIC_INTERP_POINT(:), &
      & MATERIALS_INTERP_POINT(:)
    TYPE(FIELD_INTERPOLATED_POINT_METRICS_PTR_TYPE), POINTER :: GEOMETRIC_INTERPOLATED_POINT_METRICS(:)
    TYPE(FIELD_PHYSICAL_POINT_PTR_TYPE), POINTER :: ANALYTIC_PHYSICAL_POINT(:),MATERIALS_PHYSICAL_POINT(:)
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: FIELD_VARIABLE
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("EQUATIONS_SET_ANALYTIC_EVALUATE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%ANALYTIC)) THEN
        IF(EQUATIONS_SET%ANALYTIC%ANALYTIC_FINISHED) THEN
          DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
          IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
            GEOMETRIC_FIELD=>EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD
            IF(ASSOCIATED(GEOMETRIC_FIELD)) THEN            
              CALL Field_NumberOfComponentsGet(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,NUMBER_OF_DIMENSIONS,ERR,ERROR,*999)
              CALL Field_InterpolationParametersInitialise(GEOMETRIC_FIELD,GEOMETRIC_INTERP_PARAMETERS,ERR,ERROR,*999)
              CALL Field_InterpolatedPointsInitialise(GEOMETRIC_INTERP_PARAMETERS,GEOMETRIC_INTERP_POINT,ERR,ERROR,*999)
              CALL Field_InterpolatedPointsMetricsInitialise(GEOMETRIC_INTERP_POINT,GEOMETRIC_INTERPOLATED_POINT_METRICS, &
                & ERR,ERROR,*999)
              ANALYTIC_FIELD=>EQUATIONS_SET%ANALYTIC%ANALYTIC_FIELD
              IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                CALL Field_NumberOfComponentsGet(ANALYTIC_FIELD,FIELD_U_VARIABLE_TYPE,NUMBER_OF_ANALYTIC_COMPONENTS, &
                  & ERR,ERROR,*999)
                CALL Field_InterpolationParametersInitialise(ANALYTIC_FIELD,ANALYTIC_INTERP_PARAMETERS,ERR,ERROR,*999)
                CALL Field_InterpolatedPointsInitialise(ANALYTIC_INTERP_PARAMETERS,ANALYTIC_INTERP_POINT,ERR,ERROR,*999)
                CALL Field_PhysicalPointsInitialise(ANALYTIC_INTERP_POINT,GEOMETRIC_INTERP_POINT,ANALYTIC_PHYSICAL_POINT, &
                  & ERR,ERROR,*999)
              ENDIF
              NULLIFY(MATERIALS_FIELD)
              IF(ASSOCIATED(EQUATIONS_SET%MATERIALS)) THEN
                MATERIALS_FIELD=>EQUATIONS_SET%MATERIALS%MATERIALS_FIELD
                CALL Field_NumberOfComponentsGet(MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE,NUMBER_OF_ANALYTIC_COMPONENTS, &
                  & ERR,ERROR,*999)
                CALL Field_InterpolationParametersInitialise(MATERIALS_FIELD,MATERIALS_INTERP_PARAMETERS,ERR,ERROR,*999)
                CALL Field_InterpolatedPointsInitialise(MATERIALS_INTERP_PARAMETERS,MATERIALS_INTERP_POINT,ERR,ERROR,*999)
                CALL Field_PhysicalPointsInitialise(MATERIALS_INTERP_POINT,GEOMETRIC_INTERP_POINT,MATERIALS_PHYSICAL_POINT, &
                  & ERR,ERROR,*999)
              ENDIF
              DO variable_idx=1,DEPENDENT_FIELD%NUMBER_OF_VARIABLES
                variable_type=DEPENDENT_FIELD%VARIABLES(variable_idx)%VARIABLE_TYPE
                FIELD_VARIABLE=>DEPENDENT_FIELD%VARIABLE_TYPE_MAP(variable_type)%PTR
                IF(ASSOCIATED(FIELD_VARIABLE)) THEN
                  DO component_idx=1,FIELD_VARIABLE%NUMBER_OF_COMPONENTS
                    DOMAIN=>FIELD_VARIABLE%COMPONENTS(component_idx)%DOMAIN
                    IF(ASSOCIATED(DOMAIN)) THEN
                      IF(ASSOCIATED(DOMAIN%TOPOLOGY)) THEN
                        SELECT CASE(FIELD_VARIABLE%COMPONENTS(component_idx)%INTERPOLATION_TYPE)
                        CASE(FIELD_CONSTANT_INTERPOLATION)
                          CALL FlagError("Cannot evaluate an analytic solution for a constant interpolation components.", &
                            & ERR,ERROR,*999)
                        CASE(FIELD_ELEMENT_BASED_INTERPOLATION)
                          DOMAIN_ELEMENTS=>DOMAIN%TOPOLOGY%ELEMENTS
                          IF(ASSOCIATED(DOMAIN_ELEMENTS)) THEN
                            !Loop over the local elements excluding the ghosts
                            DO element_idx=1,DOMAIN_ELEMENTS%NUMBER_OF_ELEMENTS
                              BASIS=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)%BASIS
                              CALL Field_InterpolationParametersElementGet(FIELD_VALUES_SET_TYPE,element_idx, &
                                & GEOMETRIC_INTERP_PARAMETERS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                                CALL Field_InterpolationParametersElementGet(FIELD_VALUES_SET_TYPE,element_idx, &
                                  & ANALYTIC_INTERP_PARAMETERS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              ENDIF
                              IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                CALL Field_InterpolationParametersElementGet(FIELD_VALUES_SET_TYPE,element_idx, &
                                  & MATERIALS_INTERP_PARAMETERS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              ENDIF
                              CALL FIELD_INTERPOLATE_XI(FIRST_PART_DERIV,[0.5_DP,0.5_DP,0.5_DP], &
                                & GEOMETRIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              CALL Field_InterpolatedPointMetricsCalculate(COORDINATE_JACOBIAN_NO_TYPE, &
                                & GEOMETRIC_INTERPOLATED_POINT_METRICS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              CALL Field_PositionNormalTangentsCalculateIntPtMetric( &
                                & GEOMETRIC_INTERPOLATED_POINT_METRICS(FIELD_U_VARIABLE_TYPE)%PTR,reverseNormal, &
                                & POSITION,NORMAL,TANGENTS,ERR,ERROR,*999)
                              IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                                CALL FIELD_INTERPOLATE_XI(NO_PART_DERIV,[0.5_DP,0.5_DP,0.5_DP], &
                                  & ANALYTIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              ENDIF
                              IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                CALL FIELD_INTERPOLATE_XI(NO_PART_DERIV,[0.5_DP,0.5_DP,0.5_DP], &
                                  & MATERIALS_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              ENDIF
!! \todo Maybe do this with optional arguments?
                              IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                                IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                  CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                    & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                    & variable_type,GLOBAL_DERIV_INDEX,component_idx, &
                                    & ANALYTIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES(:,NO_PART_DERIV), &
                                    & MATERIALS_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES(:,NO_PART_DERIV), &
                                    & VALUE,ERR,ERROR,*999)
                                ELSE
                                  CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                    & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                    & variable_type,GLOBAL_DERIV_INDEX,component_idx, &
                                    & ANALYTIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES(:,NO_PART_DERIV), &
                                    & MATERIALS_DUMMY_VALUES,VALUE,ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                  CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                    & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                    & variable_type,GLOBAL_DERIV_INDEX,component_idx,ANALYTIC_DUMMY_VALUES, &
                                    & MATERIALS_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES(:,NO_PART_DERIV), &
                                    & VALUE,ERR,ERROR,*999)
                                ELSE
                                  CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                    & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                    & variable_type,GLOBAL_DERIV_INDEX,component_idx,ANALYTIC_DUMMY_VALUES, &
                                    & MATERIALS_DUMMY_VALUES,VALUE,ERR,ERROR,*999)
                                ENDIF
                              ENDIF
                              local_ny=FIELD_VARIABLE%COMPONENTS(component_idx)%PARAM_TO_DOF_MAP% &
                                & ELEMENT_PARAM2DOF_MAP%ELEMENTS(element_idx)
                              CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type, &
                                & FIELD_ANALYTIC_VALUES_SET_TYPE,local_ny,VALUE,ERR,ERROR,*999)
                            ENDDO !element_idx
                          ELSE
                            CALL FlagError("Domain topology elements is not associated.",ERR,ERROR,*999)
                          ENDIF
                        CASE(FIELD_NODE_BASED_INTERPOLATION)
                          DOMAIN_NODES=>DOMAIN%TOPOLOGY%NODES
                          IF(ASSOCIATED(DOMAIN_NODES)) THEN
                            !Loop over the local nodes excluding the ghosts.
                            DO node_idx=1,DOMAIN_NODES%NUMBER_OF_NODES
                              CALL Field_PositionNormalTangentsCalculateNode(DEPENDENT_FIELD,variable_type,component_idx, &
                                & node_idx,POSITION,NORMAL,TANGENTS,ERR,ERROR,*999)
                              IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                                CALL FIELD_INTERPOLATE_FIELD_NODE(NO_PHYSICAL_DERIV,FIELD_VALUES_SET_TYPE,ANALYTIC_FIELD, &
                                  & FIELD_U_VARIABLE_TYPE,component_idx,node_idx,ANALYTIC_PHYSICAL_POINT( &
                                  & FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              ENDIF
                              IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                CALL FIELD_INTERPOLATE_FIELD_NODE(NO_PHYSICAL_DERIV,FIELD_VALUES_SET_TYPE,MATERIALS_FIELD, &
                                  & FIELD_U_VARIABLE_TYPE,component_idx,node_idx,MATERIALS_PHYSICAL_POINT( &
                                  & FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              ENDIF
                              !Loop over the derivatives
                              DO derivative_idx=1,DOMAIN_NODES%NODES(node_idx)%NUMBER_OF_DERIVATIVES                                
                                GLOBAL_DERIV_INDEX=DOMAIN_NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)% &
                                  & GLOBAL_DERIVATIVE_INDEX
!! \todo Maybe do this with optional arguments?
                                IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                                  IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                    CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                      & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                      & variable_type,GLOBAL_DERIV_INDEX,component_idx, &
                                      & ANALYTIC_PHYSICAL_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES, &
                                      & MATERIALS_PHYSICAL_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES,VALUE,ERR,ERROR,*999)
                                  ELSE
                                    CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                      & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                      & variable_type,GLOBAL_DERIV_INDEX,component_idx, &
                                      & ANALYTIC_PHYSICAL_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES, &
                                      & MATERIALS_DUMMY_VALUES,VALUE,ERR,ERROR,*999)
                                  ENDIF
                                ELSE
                                  IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                    CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                      & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                      & variable_type,GLOBAL_DERIV_INDEX,component_idx,ANALYTIC_DUMMY_VALUES, &
                                      & MATERIALS_PHYSICAL_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES,VALUE,ERR,ERROR,*999)
                                  ELSE
                                    CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                      & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                      & variable_type,GLOBAL_DERIV_INDEX,component_idx,ANALYTIC_DUMMY_VALUES, &
                                      & MATERIALS_DUMMY_VALUES,VALUE,ERR,ERROR,*999)
                                  ENDIF
                                ENDIF
                                !Loop over the versions
                                DO version_idx=1,DOMAIN_NODES%NODES(node_idx)%DERIVATIVES(derivative_idx)%numberOfVersions
                                  local_ny=FIELD_VARIABLE%COMPONENTS(component_idx)%PARAM_TO_DOF_MAP% &
                                    & NODE_PARAM2DOF_MAP%NODES(node_idx)%DERIVATIVES(derivative_idx)%VERSIONS(version_idx)
                                  CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type, &
                                    & FIELD_ANALYTIC_VALUES_SET_TYPE,local_ny,VALUE,ERR,ERROR,*999)
                                ENDDO !version_idx
                              ENDDO !deriv_idx
                            ENDDO !node_idx
                          ELSE
                            CALL FlagError("Domain topology nodes is not associated.",ERR,ERROR,*999)
                          ENDIF
                        CASE(FIELD_GRID_POINT_BASED_INTERPOLATION)
                          CALL FlagError("Not implemented.",ERR,ERROR,*999)
                        CASE(FIELD_GAUSS_POINT_BASED_INTERPOLATION)
                          DOMAIN_ELEMENTS=>DOMAIN%TOPOLOGY%ELEMENTS
                          IF(ASSOCIATED(DOMAIN_ELEMENTS)) THEN
                            !Loop over the local elements excluding the ghosts
                            DO element_idx=1,DOMAIN_ELEMENTS%NUMBER_OF_ELEMENTS
                              BASIS=>DOMAIN_ELEMENTS%ELEMENTS(element_idx)%BASIS
                              CALL Field_InterpolationParametersElementGet(FIELD_VALUES_SET_TYPE,element_idx, &
                                & GEOMETRIC_INTERP_PARAMETERS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                                CALL Field_InterpolationParametersElementGet(FIELD_VALUES_SET_TYPE,element_idx, &
                                  & ANALYTIC_INTERP_PARAMETERS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              ENDIF
                              IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                CALL Field_InterpolationParametersElementGet(FIELD_VALUES_SET_TYPE,element_idx, &
                                  & MATERIALS_INTERP_PARAMETERS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                              ENDIF
                              !Loop over the Gauss points in the element
                              DO gauss_idx=1,BASIS%QUADRATURE%QUADRATURE_SCHEME_MAP(BASIS_DEFAULT_QUADRATURE_SCHEME)%PTR% &
                                & NUMBER_OF_GAUSS
                                CALL Field_InterpolateGauss(FIRST_PART_DERIV,BASIS_DEFAULT_QUADRATURE_SCHEME,gauss_idx, &
                                  & GEOMETRIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                                CALL Field_InterpolatedPointMetricsCalculate(COORDINATE_JACOBIAN_NO_TYPE, &
                                  & GEOMETRIC_INTERPOLATED_POINT_METRICS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                                CALL Field_PositionNormalTangentsCalculateIntPtMetric( &
                                  & GEOMETRIC_INTERPOLATED_POINT_METRICS(FIELD_U_VARIABLE_TYPE)%PTR,reverseNormal, &
                                  & POSITION,NORMAL,TANGENTS,ERR,ERROR,*999)
                                IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                                  CALL Field_InterpolateGauss(NO_PART_DERIV,BASIS_DEFAULT_QUADRATURE_SCHEME,gauss_idx, &
                                    & ANALYTIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                                ENDIF
                                IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                  CALL Field_InterpolateGauss(NO_PART_DERIV,BASIS_DEFAULT_QUADRATURE_SCHEME,gauss_idx, &
                                    & MATERIALS_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
                                ENDIF
!! \todo Maybe do this with optional arguments?
                                IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                                  IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                    CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                      & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                      & variable_type,GLOBAL_DERIV_INDEX,component_idx, &
                                      & ANALYTIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES(:,NO_PART_DERIV), &
                                      & MATERIALS_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES(:,NO_PART_DERIV), &
                                      & VALUE,ERR,ERROR,*999)
                                  ELSE
                                    CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                      & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                      & variable_type,GLOBAL_DERIV_INDEX,component_idx, &
                                      & ANALYTIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES(:,NO_PART_DERIV), &
                                      & MATERIALS_DUMMY_VALUES,VALUE,ERR,ERROR,*999)
                                  ENDIF
                                ELSE
                                  IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                                    CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                      & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                      & variable_type,GLOBAL_DERIV_INDEX,component_idx,ANALYTIC_DUMMY_VALUES, &
                                      & MATERIALS_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%VALUES(:,NO_PART_DERIV), &
                                      & VALUE,ERR,ERROR,*999)
                                  ELSE
                                    CALL EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%ANALYTIC% &
                                      & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME, &
                                      & variable_type,GLOBAL_DERIV_INDEX,component_idx,ANALYTIC_DUMMY_VALUES, &
                                      & MATERIALS_DUMMY_VALUES,VALUE,ERR,ERROR,*999)
                                  ENDIF
                                ENDIF
                                local_ny=FIELD_VARIABLE%COMPONENTS(component_idx)%PARAM_TO_DOF_MAP% &
                                  & GAUSS_POINT_PARAM2DOF_MAP%GAUSS_POINTS(Gauss_idx,element_idx)
                                CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type, &
                                  & FIELD_ANALYTIC_VALUES_SET_TYPE,local_ny,VALUE,ERR,ERROR,*999)
                              ENDDO !Gauss_idx
                            ENDDO !element_idx
                          ELSE
                            CALL FlagError("Domain topology elements is not associated.",ERR,ERROR,*999)
                          ENDIF
                        CASE DEFAULT
                          LOCAL_ERROR="The interpolation type of "//TRIM(NUMBER_TO_VSTRING(FIELD_VARIABLE% &
                            & COMPONENTS(component_idx)%INTERPOLATION_TYPE,"*",ERR,ERROR))// &
                            & " for component "//TRIM(NUMBER_TO_VSTRING(component_idx,"*",ERR,ERROR))//" of variable type "// &
                            & TRIM(NUMBER_TO_VSTRING(variable_type,"*",ERR,ERROR))//" is invalid."
                          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                        END SELECT
                      ELSE
                        CALL FlagError("Domain topology is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      CALL FlagError("Domain is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ENDDO !component_idx
                  CALL Field_ParameterSetUpdateStart(DEPENDENT_FIELD,variable_type, &
                    & FIELD_ANALYTIC_VALUES_SET_TYPE,ERR,ERROR,*999)
                  CALL Field_ParameterSetUpdateFinish(DEPENDENT_FIELD,variable_type, &
                    & FIELD_ANALYTIC_VALUES_SET_TYPE,ERR,ERROR,*999)
                ELSE
                  CALL FlagError("Field variable is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDDO !variable_idx
              IF(ASSOCIATED(MATERIALS_FIELD)) THEN
                CALL FIELD_PHYSICAL_POINTS_FINALISE(MATERIALS_PHYSICAL_POINT,ERR,ERROR,*999)
                CALL FIELD_INTERPOLATED_POINTS_FINALISE(MATERIALS_INTERP_POINT,ERR,ERROR,*999)
                CALL FIELD_INTERPOLATION_PARAMETERS_FINALISE(MATERIALS_INTERP_PARAMETERS,ERR,ERROR,*999)
              ENDIF
              IF(ASSOCIATED(ANALYTIC_FIELD)) THEN
                CALL FIELD_PHYSICAL_POINTS_FINALISE(ANALYTIC_PHYSICAL_POINT,ERR,ERROR,*999)
                CALL FIELD_INTERPOLATED_POINTS_FINALISE(ANALYTIC_INTERP_POINT,ERR,ERROR,*999)
                CALL FIELD_INTERPOLATION_PARAMETERS_FINALISE(ANALYTIC_INTERP_PARAMETERS,ERR,ERROR,*999)
              ENDIF
              CALL Field_InterpolatedPointsMetricsFinalise(GEOMETRIC_INTERPOLATED_POINT_METRICS,ERR,ERROR,*999)
              CALL FIELD_INTERPOLATED_POINTS_FINALISE(GEOMETRIC_INTERP_POINT,ERR,ERROR,*999)
              CALL FIELD_INTERPOLATION_PARAMETERS_FINALISE(GEOMETRIC_INTERP_PARAMETERS,ERR,ERROR,*999)
              
            ELSE
              CALL FlagError("Equations set geometric field is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations set dependent field is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations set analytic has not been finished.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations set analytic is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_EVALUATE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_EVALUATE",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_EVALUATE

  !
  !================================================================================================================================
  !

  !>Finalise the analytic solution for an equations set and deallocate all memory.
  SUBROUTINE EQUATIONS_SET_ANALYTIC_FINALISE(EQUATIONS_SET_ANALYTIC,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_ANALYTIC_TYPE), POINTER :: EQUATIONS_SET_ANALYTIC !<A pointer to the equations set analytic to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_ANALYTIC_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET_ANALYTIC)) THEN        
      DEALLOCATE(EQUATIONS_SET_ANALYTIC)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_FINALISE

  !
  !================================================================================================================================
  !

  !>Evaluate the analytic solution for an equations set.
  SUBROUTINE EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,TIME, &
    & VARIABLE_TYPE,GLOBAL_DERIVATIVE,COMPONENT_NUMBER,ANALYTIC_PARAMETERS,MATERIALS_PARAMETERS,VALUE,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to evaluate the analytic for
    INTEGER(INTG), INTENT(IN) :: ANALYTIC_FUNCTION_TYPE !<The type of analytic function to evaluate
    REAL(DP), INTENT(IN) :: POSITION(:) !<POSITION(dimention_idx). The geometric position to evaluate at
    REAL(DP), INTENT(IN) :: TANGENTS(:,:) !<TANGENTS(dimention_idx,xi_idx). The geometric tangents at the point to evaluate at.
    REAL(DP), INTENT(IN) :: NORMAL(:) !<NORMAL(dimension_idx). The normal vector at the point to evaluate at.
    REAL(DP), INTENT(IN) :: TIME !<The time to evaluate at
    INTEGER(INTG), INTENT(IN) :: VARIABLE_TYPE !<The field variable type to evaluate at
    INTEGER(INTG), INTENT(IN) :: GLOBAL_DERIVATIVE !<The global derivative direction to evaluate at
    INTEGER(INTG), INTENT(IN) :: COMPONENT_NUMBER !<The dependent field component number to evaluate
    REAL(DP), INTENT(IN) :: ANALYTIC_PARAMETERS(:) !<A pointer to any analytic field parameters
    REAL(DP), INTENT(IN) :: MATERIALS_PARAMETERS(:) !<A pointer to any materials field parameters
    REAL(DP), INTENT(OUT) :: VALUE !<On return, the analtyic function value.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(.NOT.ALLOCATED(EQUATIONS_SET%SPECIFICATION)) THEN
        CALL FlagError("Equations set specification is not allocated.",err,error,*999)
      ELSE IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<1) THEN
        CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
      END IF
      SELECT CASE(EQUATIONS_SET%SPECIFICATION(1))
      CASE(EQUATIONS_SET_ELASTICITY_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
        IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<2) THEN
          CALL FlagError("Equations set specification must have at least two entries for a "// &
            & "classical field equations set.",err,error,*999)
        END IF
        CALL CLASSICAL_FIELD_ANALYTIC_FUNCTIONS_EVALUATE(EQUATIONS_SET,EQUATIONS_SET%SPECIFICATION(2), &
          & ANALYTIC_FUNCTION_TYPE,POSITION,TANGENTS,NORMAL,TIME,VARIABLE_TYPE,GLOBAL_DERIVATIVE, &
          & COMPONENT_NUMBER,ANALYTIC_PARAMETERS,MATERIALS_PARAMETERS,VALUE,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_FITTING_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_MODAL_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The first equations set specification of "// &
          & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SPECIFICATION(1),"*",ERR,ERROR))//" is not valid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_FUNCTIONS_EVALUATE

  !
  !================================================================================================================================
  !

  !>Initialises the analytic solution for an equations set.
  SUBROUTINE EQUATIONS_SET_ANALYTIC_INITIALISE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the analytic solution for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
 
    ENTERS("EQUATIONS_SET_ANALYTIC_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%ANALYTIC)) THEN
        CALL FlagError("Analytic is already associated for this equations set.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(EQUATIONS_SET%ANALYTIC,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate equations set analytic.",ERR,ERROR,*999)
        EQUATIONS_SET%ANALYTIC%EQUATIONS_SET=>EQUATIONS_SET
        EQUATIONS_SET%ANALYTIC%ANALYTIC_FINISHED=.FALSE.
        EQUATIONS_SET%ANALYTIC%ANALYTIC_FIELD_AUTO_CREATED=.FALSE.
        NULLIFY(EQUATIONS_SET%ANALYTIC%ANALYTIC_FIELD)
        EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME=0.0_DP
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_INITIALISE")
    RETURN
999 CALL EQUATIONS_SET_ANALYTIC_FINALISE(EQUATIONS_SET%ANALYTIC,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_INITIALISE",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the analytic time for an equations set. \see OPENCMISS::CMISSEquationsSetAnalyticTimeGet
  SUBROUTINE EQUATIONS_SET_ANALYTIC_TIME_GET(EQUATIONS_SET,TIME,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to get the time for.
    REAL(DP), INTENT(OUT) :: TIME !<On return, the analytic time value .
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_ANALYTIC_TIME_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%ANALYTIC)) THEN
        TIME=EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME
      ELSE
        CALL FlagError("Equations set analytic is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_TIME_GET")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_TIME_GET",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_TIME_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the analytic time for an equations set. \see OPENCMISS::CMISSEquationsSetAnalyticTimeSet
  SUBROUTINE EQUATIONS_SET_ANALYTIC_TIME_SET(EQUATIONS_SET,TIME,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to set the time for.
    REAL(DP), INTENT(IN) :: TIME !<The time value to set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_ANALYTIC_TIME_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%ANALYTIC)) THEN
        EQUATIONS_SET%ANALYTIC%ANALYTIC_TIME=TIME
      ELSE
        CALL FlagError("Equations set analytic is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ANALYTIC_TIME_SET")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_TIME_SET",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_TIME_SET

  !
  !================================================================================================================================
  !

  !>Sets the analytic problem user parameter
  SUBROUTINE EQUATIONS_SET_ANALYTIC_USER_PARAM_SET(EQUATIONS_SET,PARAM_IDX,PARAM,ERR,ERROR,*)
    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the analytic solution for.
    INTEGER(INTG), INTENT(IN) :: PARAM_IDX !<Index of the user parameter
    REAL(DP), INTENT(IN) :: PARAM !<Value of the parameter
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local variables
    TYPE(EQUATIONS_SET_ANALYTIC_TYPE), POINTER :: ANALYTIC

    ENTERS("EQUATIONS_SET_ANALYTIC_USER_PARAM_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      ANALYTIC=>EQUATIONS_SET%ANALYTIC
      IF(ASSOCIATED(ANALYTIC)) THEN
        IF(PARAM_IDX>0.AND.PARAM_IDX<=SIZE(ANALYTIC%ANALYTIC_USER_PARAMS)) THEN
          !Set the value
          ANALYTIC%ANALYTIC_USER_PARAMS(PARAM_IDX)=PARAM
        ELSE
          CALL FlagError("Invalid parameter index.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations set analytic is not associated.",ERR,ERROR,*999)
      ENDIF    
    ELSE 
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("EQUATIONS_SET_ANALYTIC_USER_PARAM_SET")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_USER_PARAM_SET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_USER_PARAM_SET

  !
  !================================================================================================================================
  !

  !>Sets the analytic problem user parameter
  SUBROUTINE EQUATIONS_SET_ANALYTIC_USER_PARAM_GET(EQUATIONS_SET,PARAM_IDX,PARAM,ERR,ERROR,*)
    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the analytic solution for.
    INTEGER(INTG), INTENT(IN) :: PARAM_IDX !<Index of the user parameter
    REAL(DP), INTENT(OUT) :: PARAM !<Value of the parameter
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local variables
    TYPE(EQUATIONS_SET_ANALYTIC_TYPE), POINTER :: ANALYTIC

    ENTERS("EQUATIONS_SET_ANALYTIC_USER_PARAM_GET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      ANALYTIC=>EQUATIONS_SET%ANALYTIC
      IF(ASSOCIATED(ANALYTIC)) THEN
        IF(PARAM_IDX>0.AND.PARAM_IDX<=SIZE(ANALYTIC%ANALYTIC_USER_PARAMS)) THEN
          !Set the value
          PARAM=ANALYTIC%ANALYTIC_USER_PARAMS(PARAM_IDX)
        ELSE
          CALL FlagError("Invalid parameter index.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations set analytic is not associated.",ERR,ERROR,*999)
      ENDIF    
    ELSE 
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("EQUATIONS_SET_ANALYTIC_USER_PARAM_GET")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ANALYTIC_USER_PARAM_GET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ANALYTIC_USER_PARAM_GET

  !
  !================================================================================================================================
  !

  !>Assembles the equations for an equations set.
  SUBROUTINE EQUATIONS_SET_ASSEMBLE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to assemble the equations for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    ENTERS("EQUATIONS_SET_ASSEMBLE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN
        IF(EQUATIONS%EQUATIONS_FINISHED) THEN
          SELECT CASE(EQUATIONS%TIME_DEPENDENCE)
          CASE(EQUATIONS_STATIC)
            SELECT CASE(EQUATIONS%LINEARITY)
            CASE(EQUATIONS_LINEAR)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_ASSEMBLE_STATIC_LINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_NODAL_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_NONLINEAR)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_ASSEMBLE_STATIC_NONLINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_NODAL_SOLUTION_METHOD)
                CALL EquationsSet_AssembleStaticNonlinearNodal(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_NONLINEAR_BCS)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The equations linearity of "// &
                & TRIM(NUMBER_TO_VSTRING(EQUATIONS%LINEARITY,"*",ERR,ERROR))//" is invalid."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          CASE(EQUATIONS_QUASISTATIC)
! chrm, 17/09/09
            SELECT CASE(EQUATIONS%LINEARITY)
            CASE(EQUATIONS_LINEAR)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EquationsSet_AssembleQuasistaticLinearFEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_NONLINEAR)
                CALL EquationsSet_AssembleQuasistaticNonlinearFEM(EQUATIONS_SET,ERR,ERROR,*999)
            CASE(EQUATIONS_NONLINEAR_BCS)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The equations linearity of "// &
                & TRIM(NUMBER_TO_VSTRING(EQUATIONS%LINEARITY,"*",ERR,ERROR))//" is invalid."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          CASE(EQUATIONS_FIRST_ORDER_DYNAMIC,EQUATIONS_SECOND_ORDER_DYNAMIC)
            SELECT CASE(EQUATIONS%LINEARITY)
            CASE(EQUATIONS_LINEAR)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_ASSEMBLE_DYNAMIC_LINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_NONLINEAR)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE(EQUATIONS_NONLINEAR_BCS)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The equations set linearity of "// &
                & TRIM(NUMBER_TO_VSTRING(EQUATIONS%LINEARITY,"*",ERR,ERROR))//" is invalid."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          CASE(EQUATIONS_TIME_STEPPING)
            CALL FlagError("Time stepping equations are not assembled.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The equations time dependence type of "// &
              & TRIM(NUMBER_TO_VSTRING(EQUATIONS%TIME_DEPENDENCE,"*",ERR,ERROR))//" is invalid."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FlagError("Equations have not been finished.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations set equations is not associated.",ERR,ERROR,*999)
      ENDIF      
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ASSEMBLE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ASSEMBLE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ASSEMBLE

  !
  !================================================================================================================================
  !
  
  !>Assembles the equations stiffness matrix and rhs for a dynamic linear equations set using the finite element method.
  SUBROUTINE EQUATIONS_SET_ASSEMBLE_DYNAMIC_LINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to assemble the equations for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_idx,ne,NUMBER_OF_TIMES
    REAL(SP) :: ELEMENT_USER_ELAPSED,ELEMENT_SYSTEM_ELAPSED,USER_ELAPSED,USER_TIME1(1),USER_TIME2(1),USER_TIME3(1),USER_TIME4(1), &
      & USER_TIME5(1),USER_TIME6(1),SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),SYSTEM_TIME3(1),SYSTEM_TIME4(1), &
      & SYSTEM_TIME5(1),SYSTEM_TIME6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    LOGICAL :: DEBUGGING = .FALSE.
    
    INTEGER(INTG) :: component_idx
    TYPE(FIELD_INTERPOLATION_PARAMETERS_TYPE), POINTER :: INTERPOLATION_PARAMETERS, INTERPOLATION_PARAMETERS_PTR
    
    
    ENTERS("EQUATIONS_SET_ASSEMBLE_DYNAMIC_LINEAR_FEM",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
        IF(ASSOCIATED(EQUATIONS)) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
            ENDIF
            !Initialise the matrices and rhs vector to 0.0_DP
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(EQUATIONS_MATRICES,EQUATIONS_MATRICES_LINEAR_ONLY,0.0_DP,ERR,ERROR,*999)
            !Assemble the elements
            !Allocate the element matrices 
            CALL EQUATIONS_MATRICES_ELEMENT_INITIALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ELEMENTS_MAPPING=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%ELEMENTS
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              ELEMENT_USER_ELAPSED=0.0_SP
              ELEMENT_SYSTEM_ELAPSED=0.0_SP
            ENDIF
            NUMBER_OF_TIMES=0
            
            IF (DEBUGGING) THEN
              PRINT*, "assemble dynamic linear FEM, loop over elements: ", ELEMENTS_MAPPING%INTERNAL_START, &
                & "to",ELEMENTS_MAPPING%INTERNAL_FINISH
                
              !CALL Print_DOMAIN_MAPPING(ELEMENTS_MAPPING, 5, 40)
              
              PRINT*, "internal elements ", ELEMENTS_MAPPING%INTERNAL_START,"to",ELEMENTS_MAPPING%INTERNAL_FINISH
              PRINT*, "geometric interpolation parameters at elements:"
              
              PRINT*, "index        element_no      interpolation_parameters"
              DO element_idx=ELEMENTS_MAPPING%INTERNAL_START, ELEMENTS_MAPPING%INTERNAL_FINISH
              
                ne = ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
                
                ! get interpolation parameters of element
                ! version which is used with real preallocated variable names:
                CALL FIELD_INTERPOLATION_PARAMETERS_ELEMENT_GET(FIELD_VALUES_SET_TYPE,ne,&
                  & EQUATIONS%INTERPOLATION%GEOMETRIC_INTERP_PARAMETERS(FIELD_U_VARIABLE_TYPE)%PTR,ERR,ERROR,*999)
          
                INTERPOLATION_PARAMETERS=> &
                  & EQUATIONS%INTERPOLATION%GEOMETRIC_INTERP_POINT(FIELD_U_VARIABLE_TYPE)%PTR%INTERPOLATION_PARAMETERS                
                
                ! direct version
                CALL FIELD_INTERPOLATION_PARAMETERS_ELEMENT_GET(FIELD_VALUES_SET_TYPE,ne,INTERPOLATION_PARAMETERS,ERR,ERROR,*999)
                
                DO component_idx = 1,INTERPOLATION_PARAMETERS%FIELD_VARIABLE%NUMBER_OF_COMPONENTS
                  PRINT*, element_idx, ne, INTERPOLATION_PARAMETERS%PARAMETERS(:,component_idx)
                ENDDO
              ENDDO
              
            ENDIF
            
            !Loop over the internal elements
            DO element_idx=ELEMENTS_MAPPING%INTERNAL_START, ELEMENTS_MAPPING%INTERNAL_FINISH
              !here only the internal elements are considered
              
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              IF (DEBUGGING) PRINT*, "element index ", element_idx,", ne=",ne
              
              !CALL Print_EQUATIONS_MATRICES(EQUATIONS_MATRICES, 4, 5)
              !PRINT*, "======================"
              !CALL Print_EQUATIONS_SET(EQUATIONS_SET, 4, 5)
              !STOP
              
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              
              CALL EQUATIONS_SET_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ne,ERR,ERROR,*999)
              
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            
            !PRINT*, "Stop execution in equations_set_routines.f90:1257"
            !STOP
            
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME3,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME3,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME3(1)-USER_TIME2(1)
              SYSTEM_ELAPSED=SYSTEM_TIME3(1)-SYSTEM_TIME2(1)
              ELEMENT_USER_ELAPSED=USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=SYSTEM_ELAPSED
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
             ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME4,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME4,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME4(1)-USER_TIME3(1)
              SYSTEM_ELAPSED=SYSTEM_TIME4(1)-SYSTEM_TIME3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Loop over the boundary and ghost elements
            DO element_idx=ELEMENTS_MAPPING%BOUNDARY_START,ELEMENTS_MAPPING%GHOST_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EQUATIONS_SET_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME5,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME5,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME5(1)-USER_TIME4(1)
              SYSTEM_ELAPSED=SYSTEM_TIME5(1)-SYSTEM_TIME4(1)
              ELEMENT_USER_ELAPSED=ELEMENT_USER_ELAPSED+USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=ELEMENT_SYSTEM_ELAPSED+USER_ELAPSED
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              IF(NUMBER_OF_TIMES>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element user time for equations assembly = ", &
                  & ELEMENT_USER_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element system time for equations assembly = ", &
                  & ELEMENT_SYSTEM_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Finalise the element matrices
            CALL EQUATIONS_MATRICES_ELEMENT_FINALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            !Output equations matrices and RHS vector if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME6,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME6,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME6(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME6(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ASSEMBLE_DYNAMIC_LINEAR_FEM")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ASSEMBLE_DYNAMIC_LINEAR_FEM",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ASSEMBLE_DYNAMIC_LINEAR_FEM

  !
  !================================================================================================================================
  !
  
  !>Assembles the equations stiffness matrix and rhs for a linear static equations set using the finite element method.
  SUBROUTINE EQUATIONS_SET_ASSEMBLE_STATIC_LINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to assemble the equations for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_idx,ne,NUMBER_OF_TIMES
    REAL(SP) :: ELEMENT_USER_ELAPSED,ELEMENT_SYSTEM_ELAPSED,USER_ELAPSED,USER_TIME1(1),USER_TIME2(1),USER_TIME3(1),USER_TIME4(1), &
      & USER_TIME5(1),USER_TIME6(1),SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),SYSTEM_TIME3(1),SYSTEM_TIME4(1), &
      & SYSTEM_TIME5(1),SYSTEM_TIME6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    
!#ifdef TAUPROF
!    CHARACTER(28) :: CVAR
!    INTEGER :: PHASE(2)= (/ 0, 0 /)
!    SAVE PHASE
!#endif

    ENTERS("EQUATIONS_SET_ASSEMBLE_STATIC_LINEAR_FEM",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
        IF(ASSOCIATED(EQUATIONS)) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
            ENDIF
            !Initialise the matrices and rhs vector
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_START("EQUATIONS_MATRICES_VALUES_INITIALISE()")
#endif
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(EQUATIONS_MATRICES,EQUATIONS_MATRICES_LINEAR_ONLY,0.0_DP,ERR,ERROR,*999)
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_STOP("EQUATIONS_MATRICES_VALUES_INITIALISE()")
#endif
            !Assemble the elements
            !Allocate the element matrices 
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_START("EQUATIONS_MATRICES_ELEMENT_INITIALISE()")
#endif
            CALL EQUATIONS_MATRICES_ELEMENT_INITIALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ELEMENTS_MAPPING=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%ELEMENTS
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_STOP("EQUATIONS_MATRICES_ELEMENT_INITIALISE()")
#endif
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              ELEMENT_USER_ELAPSED=0.0_SP
              ELEMENT_SYSTEM_ELAPSED=0.0_SP
            ENDIF
            NUMBER_OF_TIMES=0
            !Loop over the internal elements

#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_START("Internal Elements Loop")
#endif
            DO element_idx=ELEMENTS_MAPPING%INTERNAL_START,ELEMENTS_MAPPING%INTERNAL_FINISH
!#ifdef TAUPROF
!              WRITE (CVAR,'(a23,i3)') 'Internal Elements Loop ',element_idx
!              CALL TAU_PHASE_CREATE_DYNAMIC(PHASE,CVAR)
!              CALL TAU_PHASE_START(PHASE)
!#endif
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EQUATIONS_SET_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
!#ifdef TAUPROF
!              CALL TAU_PHASE_STOP(PHASE)
!#endif
            ENDDO !element_idx
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_STOP("Internal Elements Loop")
#endif

            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME3,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME3,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME3(1)-USER_TIME2(1)
              SYSTEM_ELAPSED=SYSTEM_TIME3(1)-SYSTEM_TIME2(1)
              ELEMENT_USER_ELAPSED=USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=SYSTEM_ELAPSED
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
             ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME4,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME4,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME4(1)-USER_TIME3(1)
              SYSTEM_ELAPSED=SYSTEM_TIME4(1)-SYSTEM_TIME3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Loop over the boundary and ghost elements
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_START("Boundary and Ghost Elements Loop")
#endif
            DO element_idx=ELEMENTS_MAPPING%BOUNDARY_START,ELEMENTS_MAPPING%GHOST_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EQUATIONS_SET_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_STOP("Boundary and Ghost Elements Loop")
#endif
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME5,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME5,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME5(1)-USER_TIME4(1)
              SYSTEM_ELAPSED=SYSTEM_TIME5(1)-SYSTEM_TIME4(1)
              ELEMENT_USER_ELAPSED=ELEMENT_USER_ELAPSED+USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=ELEMENT_SYSTEM_ELAPSED+USER_ELAPSED
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              IF(NUMBER_OF_TIMES>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element user time for equations assembly = ", &
                  & ELEMENT_USER_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element system time for equations assembly = ", &
                  & ELEMENT_SYSTEM_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Finalise the element matrices
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_START("EQUATIONS_MATRICES_ELEMENT_FINALISE()")
#endif
            CALL EQUATIONS_MATRICES_ELEMENT_FINALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
#ifdef TAUPROF
            CALL TAU_STATIC_PHASE_STOP("EQUATIONS_MATRICES_ELEMENT_FINALISE()")
#endif
            !Output equations matrices and vector if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME6,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME6,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME6(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME6(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ASSEMBLE_STATIC_LINEAR_FEM")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ASSEMBLE_STATIC_LINEAR_FEM",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ASSEMBLE_STATIC_LINEAR_FEM

  !
  !================================================================================================================================
  !
  
  !>Assembles the equations stiffness matrix, residuals and rhs for a nonlinear static equations set using the finite element method.
  SUBROUTINE EQUATIONS_SET_ASSEMBLE_STATIC_NONLINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to assemble the equations for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_idx,ne,NUMBER_OF_TIMES
    REAL(SP) :: ELEMENT_USER_ELAPSED,ELEMENT_SYSTEM_ELAPSED,USER_ELAPSED,USER_TIME1(1),USER_TIME2(1),USER_TIME3(1),USER_TIME4(1), &
      & USER_TIME5(1),USER_TIME6(1),SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),SYSTEM_TIME3(1),SYSTEM_TIME4(1), &
      & SYSTEM_TIME5(1),SYSTEM_TIME6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD

    INTEGER(INTG) :: ComputationalNodeNumber, NumberOfComputationalNodes, I
    
    ENTERS("EQUATIONS_SET_ASSEMBLE_STATIC_NONLINEAR_FEM",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
        IF(ASSOCIATED(EQUATIONS)) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
            ENDIF
             !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(EQUATIONS_MATRICES,EQUATIONS_MATRICES_NONLINEAR_ONLY,0.0_DP,ERR,ERROR,*999)
            !Assemble the elements
            !Allocate the element matrices 
            CALL EQUATIONS_MATRICES_ELEMENT_INITIALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ELEMENTS_MAPPING=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%ELEMENTS

            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              ELEMENT_USER_ELAPSED=0.0_SP
              ELEMENT_SYSTEM_ELAPSED=0.0_SP
            ENDIF
            NUMBER_OF_TIMES=0

            IF (.FALSE.) THEN
            ! Debugging output in critical section
            CALL MPI_Comm_Size(MPI_COMM_WORLD, NumberOfComputationalNodes, Err)
            CALL MPI_Comm_Rank(MPI_COMM_WORLD, ComputationalNodeNumber, Err)

            DO I = 0, NumberOfComputationalNodes

              IF (ComputationalNodeNumber == I .AND. .FALSE.) THEN

                PRINT*, "Process ",I
                PRINT*, "Loop in equations_set_routines.f90, line 1561"
                PRINT*, "  loop over internal elements: ", ELEMENTS_MAPPING%INTERNAL_START, " to ", ELEMENTS_MAPPING%INTERNAL_FINISH
                DO element_idx = ELEMENTS_MAPPING%INTERNAL_START, ELEMENTS_MAPPING%INTERNAL_FINISH
                  ne = ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
                  WRITE(*,"(I0.3,A,I0.3,A)", ADVANCE="no") element_idx,"->",ne, ", "
                ENDDO

                PRINT*, "  loop over boundary+ghost elements: ", ELEMENTS_MAPPING%BOUNDARY_START, &
                  & " to ", ELEMENTS_MAPPING%GHOST_FINISH
                PRINT*, "  (boundary: ", ELEMENTS_MAPPING%BOUNDARY_START, &
                  & " to ", ELEMENTS_MAPPING%BOUNDARY_FINISH
                PRINT*, "  ghost: ", ELEMENTS_MAPPING%GHOST_START, &
                  & " to ", ELEMENTS_MAPPING%GHOST_FINISH, ")"
                DO element_idx = ELEMENTS_MAPPING%BOUNDARY_START, ELEMENTS_MAPPING%GHOST_FINISH
                  ne = ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
                  WRITE(*,"(I0.3,A,I0.3,A)", ADVANCE="no") element_idx,"->",ne, ", "
                ENDDO
              ENDIF
              CALL MPI_Barrier(MPI_COMM_WORLD, Err)

            ENDDO
            END IF

            !Loop over the internal elements
            DO element_idx = ELEMENTS_MAPPING%INTERNAL_START, ELEMENTS_MAPPING%INTERNAL_FINISH
              ne = ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES = NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              !PRINT*, "EquationsSet_FiniteElementResidualEvaluate(equation_set_routines.f90:1591)"
              CALL EquationsSet_FiniteElementResidualEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              
              !PRINT*, "Equations_SET"
              !CALL Print_EQUATIONS_SET(EQUATIONS_SET, 2, 10)
              
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx

            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME3,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME3,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME3(1)-USER_TIME2(1)
              SYSTEM_ELAPSED=SYSTEM_TIME3(1)-SYSTEM_TIME2(1)
              ELEMENT_USER_ELAPSED=USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=SYSTEM_ELAPSED
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME4,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME4,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME4(1)-USER_TIME3(1)
              SYSTEM_ELAPSED=SYSTEM_TIME4(1)-SYSTEM_TIME3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF

            !Loop over the boundary and ghost elements
            DO element_idx = ELEMENTS_MAPPING%BOUNDARY_START, ELEMENTS_MAPPING%GHOST_FINISH
              ne = ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES = NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              !PRINT*, "EquationsSet_FiniteElementResidualEvaluate(1624)"
              CALL EquationsSet_FiniteElementResidualEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx

            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME5,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME5,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME5(1)-USER_TIME4(1)
              SYSTEM_ELAPSED=SYSTEM_TIME5(1)-SYSTEM_TIME4(1)
              ELEMENT_USER_ELAPSED=ELEMENT_USER_ELAPSED+USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=ELEMENT_SYSTEM_ELAPSED+USER_ELAPSED
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              IF(NUMBER_OF_TIMES>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element user time for equations assembly = ", &
                  & ELEMENT_USER_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element system time for equations assembly = ", &
                  & ELEMENT_SYSTEM_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Finalise the element matrices
            CALL EQUATIONS_MATRICES_ELEMENT_FINALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            !Output equations matrices and RHS vector if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME6,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME6,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME6(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME6(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_ASSEMBLE_STATIC_NONLINEAR_FEM")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_ASSEMBLE_STATIC_NONLINEAR_FEM",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_ASSEMBLE_STATIC_NONLINEAR_FEM

  !
  !================================================================================================================================
  !

  !>Assembles the equations stiffness matrix, residuals and rhs for a nonlinear quasistatic equations set using the finite element method.
  !> currently the same as the static nonlinear case
  SUBROUTINE EquationsSet_AssembleQuasistaticNonlinearFEM(EQUATIONS_SET,ERR,ERROR,*)
    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to assemble the equations for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    ENTERS("EquationsSet_AssembleQuasistaticNonlinearFEM",ERR,ERROR,*999)

    ! currently no difference
    CALL EQUATIONS_SET_ASSEMBLE_STATIC_NONLINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*999)
    
    RETURN
999 ERRORS("EquationsSet_AssembleQuasistaticNonlinearFEM",ERR,ERROR)
    EXITS("EquationsSet_AssembleQuasistaticNonlinearFEM")
    RETURN 1
    
  END  SUBROUTINE EquationsSet_AssembleQuasistaticNonlinearFEM

  !
  !================================================================================================================================
  !

  !>Assembles the equations stiffness matrix and rhs for a linear quasistatic equations set using the finite element method.
  SUBROUTINE EquationsSet_AssembleQuasistaticLinearFEM(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to assemble the equations for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_idx,ne,NUMBER_OF_TIMES
    REAL(SP) :: ELEMENT_USER_ELAPSED,ELEMENT_SYSTEM_ELAPSED,USER_ELAPSED,USER_TIME1(1),USER_TIME2(1),USER_TIME3(1),USER_TIME4(1), &
      & USER_TIME5(1),USER_TIME6(1),SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),SYSTEM_TIME3(1),SYSTEM_TIME4(1), &
      & SYSTEM_TIME5(1),SYSTEM_TIME6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    
    ENTERS("EquationsSet_AssembleQuasistaticLinearFEM",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
        IF(ASSOCIATED(EQUATIONS)) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
            ENDIF
            !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(EQUATIONS_MATRICES,EQUATIONS_MATRICES_LINEAR_ONLY,0.0_DP,ERR,ERROR,*999)
            !Assemble the elements
            !Allocate the element matrices 
            CALL EQUATIONS_MATRICES_ELEMENT_INITIALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ELEMENTS_MAPPING=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%ELEMENTS
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              ELEMENT_USER_ELAPSED=0.0_SP
              ELEMENT_SYSTEM_ELAPSED=0.0_SP
            ENDIF
            NUMBER_OF_TIMES=0
            !Loop over the internal elements
            DO element_idx=ELEMENTS_MAPPING%INTERNAL_START,ELEMENTS_MAPPING%INTERNAL_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EQUATIONS_SET_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME3,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME3,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME3(1)-USER_TIME2(1)
              SYSTEM_ELAPSED=SYSTEM_TIME3(1)-SYSTEM_TIME2(1)
              ELEMENT_USER_ELAPSED=USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=SYSTEM_ELAPSED
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
             ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME4,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME4,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME4(1)-USER_TIME3(1)
              SYSTEM_ELAPSED=SYSTEM_TIME4(1)-SYSTEM_TIME3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Loop over the boundary and ghost elements
            DO element_idx=ELEMENTS_MAPPING%BOUNDARY_START,ELEMENTS_MAPPING%GHOST_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EQUATIONS_SET_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME5,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME5,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME5(1)-USER_TIME4(1)
              SYSTEM_ELAPSED=SYSTEM_TIME5(1)-SYSTEM_TIME4(1)
              ELEMENT_USER_ELAPSED=ELEMENT_USER_ELAPSED+USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=ELEMENT_SYSTEM_ELAPSED+USER_ELAPSED
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              IF(NUMBER_OF_TIMES>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element user time for equations assembly = ", &
                  & ELEMENT_USER_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element system time for equations assembly = ", &
                  & ELEMENT_SYSTEM_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Finalise the element matrices
            CALL EQUATIONS_MATRICES_ELEMENT_FINALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            !Output equations matrices and RHS vector if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME6,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME6,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME6(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME6(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EquationsSet_AssembleQuasistaticLinearFEM")
    RETURN
999 ERRORSEXITS("EquationsSet_AssembleQuasistaticLinearFEM",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EquationsSet_AssembleQuasistaticLinearFEM

  !
  !================================================================================================================================
  !

  !>Backsubstitutes with an equations set to calculate unknown right hand side vectors
  SUBROUTINE EQUATIONS_SET_BACKSUBSTITUTE(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to backsubstitute
    TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS !<The boundary conditions to use for the backsubstitution
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: equations_column_idx,equations_column_number,equations_matrix_idx,equations_row_number, &
      & EQUATIONS_STORAGE_TYPE,rhs_boundary_condition,rhs_global_dof,rhs_variable_dof,RHS_VARIABLE_TYPE,variable_dof,VARIABLE_TYPE
    INTEGER(INTG), POINTER :: COLUMN_INDICES(:),ROW_INDICES(:)
    REAL(DP) :: DEPENDENT_VALUE,MATRIX_VALUE,RHS_VALUE,SOURCE_VALUE
    REAL(DP), POINTER :: DEPENDENT_PARAMETERS(:),EQUATIONS_MATRIX_DATA(:),SOURCE_VECTOR_DATA(:)
    TYPE(BOUNDARY_CONDITIONS_VARIABLE_TYPE), POINTER :: RHS_BOUNDARY_CONDITIONS
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: COLUMN_DOMAIN_MAPPING,RHS_DOMAIN_MAPPING
    TYPE(DISTRIBUTED_MATRIX_TYPE), POINTER :: EQUATIONS_DISTRIBUTED_MATRIX
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: SOURCE_DISTRIBUTED_VECTOR
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_LINEAR_TYPE), POINTER :: LINEAR_MAPPING
    TYPE(EQUATIONS_MAPPING_RHS_TYPE), POINTER :: RHS_MAPPING
    TYPE(EQUATIONS_MAPPING_SOURCE_TYPE), POINTER :: SOURCE_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_DYNAMIC_TYPE), POINTER :: DYNAMIC_MATRICES
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: LINEAR_MATRICES
    TYPE(EQUATIONS_MATRICES_SOURCE_TYPE), POINTER :: SOURCE_VECTOR
    TYPE(EQUATIONS_MATRIX_TYPE), POINTER :: EQUATIONS_MATRIX
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DEPENDENT_VARIABLE,RHS_VARIABLE
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    NULLIFY(DEPENDENT_PARAMETERS)
    NULLIFY(EQUATIONS_MATRIX_DATA)
    NULLIFY(SOURCE_VECTOR_DATA)

    ENTERS("EQUATIONS_SET_BACKSUBSTITUTE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(EQUATIONS_SET%EQUATIONS_SET_FINISHED) THEN
        DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
        IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
          EQUATIONS=>EQUATIONS_SET%EQUATIONS
          IF(ASSOCIATED(EQUATIONS)) THEN
            EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
            IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
              DYNAMIC_MATRICES=>EQUATIONS_MATRICES%DYNAMIC_MATRICES
              IF(ASSOCIATED(DYNAMIC_MATRICES)) THEN
                !CALL FlagError("Not implemented.",ERR,ERROR,*999)
              ELSE
                LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
                IF(ASSOCIATED(LINEAR_MATRICES)) THEN
                  EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                  IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                    LINEAR_MAPPING=>EQUATIONS_MAPPING%LINEAR_MAPPING
                    IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                      RHS_MAPPING=>EQUATIONS_MAPPING%RHS_MAPPING
                      SOURCE_MAPPING=>EQUATIONS_MAPPING%SOURCE_MAPPING
                      IF(ASSOCIATED(RHS_MAPPING)) THEN
                        IF(ASSOCIATED(BOUNDARY_CONDITIONS)) THEN
                          IF(ASSOCIATED(SOURCE_MAPPING)) THEN
                            SOURCE_VECTOR=>EQUATIONS_MATRICES%SOURCE_VECTOR
                            IF(ASSOCIATED(SOURCE_VECTOR)) THEN
                              SOURCE_DISTRIBUTED_VECTOR=>SOURCE_VECTOR%VECTOR
                              IF(ASSOCIATED(SOURCE_DISTRIBUTED_VECTOR)) THEN
                                CALL DISTRIBUTED_VECTOR_DATA_GET(SOURCE_DISTRIBUTED_VECTOR,SOURCE_VECTOR_DATA,ERR,ERROR,*999)
                              ELSE
                                CALL FlagError("Source distributed vector is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FlagError("Source vector is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ENDIF
                          RHS_VARIABLE=>RHS_MAPPING%RHS_VARIABLE
                          IF(ASSOCIATED(RHS_VARIABLE)) THEN
                            RHS_VARIABLE_TYPE=RHS_VARIABLE%VARIABLE_TYPE
                            RHS_DOMAIN_MAPPING=>RHS_VARIABLE%DOMAIN_MAPPING
                            IF(ASSOCIATED(RHS_DOMAIN_MAPPING)) THEN
                              CALL BOUNDARY_CONDITIONS_VARIABLE_GET(BOUNDARY_CONDITIONS,RHS_VARIABLE,RHS_BOUNDARY_CONDITIONS, &
                                & ERR,ERROR,*999)
                              IF(ASSOCIATED(RHS_BOUNDARY_CONDITIONS)) THEN
                                !Loop over the equations matrices
                                DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                  DEPENDENT_VARIABLE=>LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)%VARIABLE
                                  IF(ASSOCIATED(DEPENDENT_VARIABLE)) THEN
                                    VARIABLE_TYPE=DEPENDENT_VARIABLE%VARIABLE_TYPE
                                    !Get the dependent field variable parameters
                                    CALL Field_ParameterSetDataGet(DEPENDENT_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                      & DEPENDENT_PARAMETERS,ERR,ERROR,*999)
                                    EQUATIONS_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                    IF(ASSOCIATED(EQUATIONS_MATRIX)) THEN
                                      COLUMN_DOMAIN_MAPPING=>LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)% &
                                        & COLUMN_DOFS_MAPPING
                                      IF(ASSOCIATED(COLUMN_DOMAIN_MAPPING)) THEN
                                        EQUATIONS_DISTRIBUTED_MATRIX=>EQUATIONS_MATRIX%MATRIX
                                        IF(ASSOCIATED(EQUATIONS_DISTRIBUTED_MATRIX)) THEN
                                          CALL DISTRIBUTED_MATRIX_STORAGE_TYPE_GET(EQUATIONS_DISTRIBUTED_MATRIX, &
                                            & EQUATIONS_STORAGE_TYPE,ERR,ERROR,*999)
                                          CALL DISTRIBUTED_MATRIX_DATA_GET(EQUATIONS_DISTRIBUTED_MATRIX,EQUATIONS_MATRIX_DATA, &
                                            & ERR,ERROR,*999)
                                          SELECT CASE(EQUATIONS_STORAGE_TYPE)
                                          CASE(DISTRIBUTED_MATRIX_BLOCK_STORAGE_TYPE)
                                            !Loop over the non ghosted rows in the equations set
                                            DO equations_row_number=1,EQUATIONS_MAPPING%NUMBER_OF_ROWS
                                              RHS_VALUE=0.0_DP
                                              rhs_variable_dof=RHS_MAPPING%EQUATIONS_ROW_TO_RHS_DOF_MAP(equations_row_number)
                                              rhs_global_dof=RHS_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(rhs_variable_dof)
                                              rhs_boundary_condition=RHS_BOUNDARY_CONDITIONS%DOF_TYPES(rhs_global_dof)
                                              !For free RHS DOFs, set the right hand side field values by multiplying the
                                              !row by the dependent variable value
                                              SELECT CASE(rhs_boundary_condition)
                                              CASE(BOUNDARY_CONDITION_DOF_FREE)
                                                !Back substitute
                                                !Loop over the local columns of the equations matrix
                                                DO equations_column_idx=1,COLUMN_DOMAIN_MAPPING%TOTAL_NUMBER_OF_LOCAL
                                                  equations_column_number=COLUMN_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP( &
                                                    & equations_column_idx)
                                                  variable_dof=equations_column_idx
                                                  MATRIX_VALUE=EQUATIONS_MATRIX_DATA(equations_row_number+ &
                                                    & (equations_column_number-1)*EQUATIONS_MATRICES%TOTAL_NUMBER_OF_ROWS)
                                                  DEPENDENT_VALUE=DEPENDENT_PARAMETERS(variable_dof)
                                                  RHS_VALUE=RHS_VALUE+MATRIX_VALUE*DEPENDENT_VALUE
                                                ENDDO !equations_column_idx
                                              CASE(BOUNDARY_CONDITION_DOF_FIXED)
                                                !Do nothing
                                              CASE(BOUNDARY_CONDITION_DOF_MIXED)
                                                !Robin or is it Cauchy??? boundary conditions
                                                CALL FlagError("Not implemented.",ERR,ERROR,*999)
                                              CASE DEFAULT
                                                LOCAL_ERROR="The RHS variable boundary condition of "// &
                                                  & TRIM(NUMBER_TO_VSTRING(rhs_boundary_condition,"*",ERR,ERROR))// &
                                                  & " for RHS variable dof number "// &
                                                  & TRIM(NUMBER_TO_VSTRING(rhs_variable_dof,"*",ERR,ERROR))//" is invalid."
                                                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                                              END SELECT
                                              IF(ASSOCIATED(SOURCE_MAPPING)) THEN
                                                SOURCE_VALUE=SOURCE_VECTOR_DATA(equations_row_number)
                                                RHS_VALUE=RHS_VALUE-SOURCE_VALUE
                                              ENDIF
                                              CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,RHS_VARIABLE_TYPE, &
                                                & FIELD_VALUES_SET_TYPE,rhs_variable_dof,RHS_VALUE,ERR,ERROR,*999)
                                            ENDDO !equations_row_number
                                          CASE(DISTRIBUTED_MATRIX_DIAGONAL_STORAGE_TYPE)
                                            CALL FlagError("Not implemented.",ERR,ERROR,*999)
                                          CASE(DISTRIBUTED_MATRIX_COLUMN_MAJOR_STORAGE_TYPE)
                                            CALL FlagError("Not implemented.",ERR,ERROR,*999)
                                          CASE(DISTRIBUTED_MATRIX_ROW_MAJOR_STORAGE_TYPE)
                                            CALL FlagError("Not implemented.",ERR,ERROR,*999)
                                          CASE(DISTRIBUTED_MATRIX_COMPRESSED_ROW_STORAGE_TYPE)
                                            CALL DISTRIBUTED_MATRIX_STORAGE_LOCATIONS_GET(EQUATIONS_DISTRIBUTED_MATRIX, &
                                              & ROW_INDICES,COLUMN_INDICES,ERR,ERROR,*999)
                                            !Loop over the non-ghosted rows in the equations set
                                            DO equations_row_number=1,EQUATIONS_MAPPING%NUMBER_OF_ROWS
                                              RHS_VALUE=0.0_DP
                                              rhs_variable_dof=RHS_MAPPING%EQUATIONS_ROW_TO_RHS_DOF_MAP(equations_row_number)
                                              rhs_global_dof=RHS_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(rhs_variable_dof)
                                              rhs_boundary_condition=RHS_BOUNDARY_CONDITIONS%DOF_TYPES(rhs_global_dof)
                                              SELECT CASE(rhs_boundary_condition)
                                              CASE(BOUNDARY_CONDITION_DOF_FREE)
                                                !Back substitute
                                                !Loop over the local columns of the equations matrix
                                                DO equations_column_idx=ROW_INDICES(equations_row_number), &
                                                  ROW_INDICES(equations_row_number+1)-1
                                                  equations_column_number=COLUMN_INDICES(equations_column_idx)
                                                  variable_dof=equations_column_idx-ROW_INDICES(equations_row_number)+1
                                                  MATRIX_VALUE=EQUATIONS_MATRIX_DATA(equations_column_idx)
                                                  DEPENDENT_VALUE=DEPENDENT_PARAMETERS(variable_dof)
                                                  RHS_VALUE=RHS_VALUE+MATRIX_VALUE*DEPENDENT_VALUE
                                                ENDDO !equations_column_idx
                                              CASE(BOUNDARY_CONDITION_DOF_FIXED)
                                                !Do nothing
                                              CASE(BOUNDARY_CONDITION_DOF_MIXED)
                                                !Robin or is it Cauchy??? boundary conditions
                                                CALL FlagError("Not implemented.",ERR,ERROR,*999)
                                              CASE DEFAULT
                                                LOCAL_ERROR="The global boundary condition of "// &
                                                  & TRIM(NUMBER_TO_VSTRING(rhs_boundary_condition,"*",ERR,ERROR))// &
                                                  & " for RHS variable dof number "// &
                                                  & TRIM(NUMBER_TO_VSTRING(rhs_variable_dof,"*",ERR,ERROR))//" is invalid."
                                                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                                              END SELECT
                                              IF(ASSOCIATED(SOURCE_MAPPING)) THEN
                                                SOURCE_VALUE=SOURCE_VECTOR_DATA(equations_row_number)
                                                RHS_VALUE=RHS_VALUE-SOURCE_VALUE
                                              ENDIF
                                              CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,RHS_VARIABLE_TYPE, &
                                                & FIELD_VALUES_SET_TYPE,rhs_variable_dof,RHS_VALUE,ERR,ERROR,*999)
                                            ENDDO !equations_row_number
                                          CASE(DISTRIBUTED_MATRIX_COMPRESSED_COLUMN_STORAGE_TYPE)
                                            CALL FlagError("Not implemented.",ERR,ERROR,*999)
                                          CASE(DISTRIBUTED_MATRIX_ROW_COLUMN_STORAGE_TYPE)
                                            CALL FlagError("Not implemented.",ERR,ERROR,*999)
                                          CASE DEFAULT
                                            LOCAL_ERROR="The matrix storage type of "// &
                                              & TRIM(NUMBER_TO_VSTRING(EQUATIONS_STORAGE_TYPE,"*",ERR,ERROR))//" is invalid."
                                            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                                          END SELECT
                                          CALL DISTRIBUTED_MATRIX_DATA_RESTORE(EQUATIONS_DISTRIBUTED_MATRIX,EQUATIONS_MATRIX_DATA, &
                                            & ERR,ERROR,*999)
                                        ELSE
                                          CALL FlagError("Equations matrix distributed matrix is not associated.",ERR,ERROR,*999)
                                        ENDIF
                                      ELSE
                                        CALL FlagError("Equations column domain mapping is not associated.",ERR,ERROR,*999)
                                      ENDIF
                                    ELSE
                                      CALL FlagError("Equations equations matrix is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                    !Restore the dependent field variable parameters
                                    CALL Field_ParameterSetDataRestore(DEPENDENT_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                      & DEPENDENT_PARAMETERS,ERR,ERROR,*999)
                                  ELSE
                                    CALL FlagError("Dependent variable is not associated.",ERR,ERROR,*999)
                                  ENDIF
                                ENDDO !equations_matrix_idx
                                !Start the update of the field parameters
                                CALL Field_ParameterSetUpdateStart(DEPENDENT_FIELD,RHS_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                  & ERR,ERROR,*999)
                                !Finish the update of the field parameters
                                CALL Field_ParameterSetUpdateFinish(DEPENDENT_FIELD,RHS_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                  & ERR,ERROR,*999)
                              ELSE
                                CALL FlagError("RHS boundary conditions variable is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FlagError("RHS variable domain mapping is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FlagError("RHS variable is not associated.",ERR,ERROR,*999)
                          ENDIF
                          IF(ASSOCIATED(SOURCE_MAPPING)) THEN
                            CALL DISTRIBUTED_VECTOR_DATA_RESTORE(SOURCE_DISTRIBUTED_VECTOR,SOURCE_VECTOR_DATA,ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FlagError("Boundary conditions are not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        CALL FlagError("Equations mapping RHS mappings is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      CALL FlagError("Equations mapping linear mapping is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FlagError("Equations mapping is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("Equations matrices linear matrices is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDIF
            ELSE
              CALL FlagError("Equations matrices is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Dependent field is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE            
        CALL FlagError("Equations set has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
          
    EXITS("EQUATIONS_SET_BACKSUBSTITUTE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_BACKSUBSTITUTE",ERR,ERROR)
    RETURN 1
   
  END SUBROUTINE EQUATIONS_SET_BACKSUBSTITUTE
  
  !
  !================================================================================================================================
  !

  !>Updates the right hand side variable from the equations residual vector
  SUBROUTINE EQUATIONS_SET_NONLINEAR_RHS_UPDATE(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set
    TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS !<Boundary conditions to use for the RHS update
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: variable_dof,row_idx,VARIABLE_TYPE,rhs_global_dof,rhs_boundary_condition,equations_matrix_idx
    REAL(DP) :: VALUE
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_NONLINEAR_TYPE), POINTER :: NONLINEAR_MAPPING
    TYPE(EQUATIONS_MAPPING_RHS_TYPE), POINTER :: RHS_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: RESIDUAL_VECTOR
    TYPE(FIELD_TYPE), POINTER :: RHS_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: RHS_VARIABLE,RESIDUAL_VARIABLE
    TYPE(BOUNDARY_CONDITIONS_VARIABLE_TYPE), POINTER :: RHS_BOUNDARY_CONDITIONS
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: RHS_DOMAIN_MAPPING
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("EQUATIONS_SET_NONLINEAR_RHS_UPDATE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN
        EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
        IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
          RHS_MAPPING=>EQUATIONS_MAPPING%RHS_MAPPING
          IF(ASSOCIATED(RHS_MAPPING)) THEN
            RHS_VARIABLE=>RHS_MAPPING%RHS_VARIABLE
            IF(ASSOCIATED(RHS_VARIABLE)) THEN
              !Get the right hand side variable
              RHS_FIELD=>RHS_VARIABLE%FIELD
              VARIABLE_TYPE=RHS_VARIABLE%VARIABLE_TYPE
            ELSE
              CALL FlagError("RHS mapping RHS variable is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations mapping RHS mapping is not associated.",ERR,ERROR,*999)
          ENDIF
          IF(ASSOCIATED(RHS_FIELD)) THEN
            IF(ASSOCIATED(BOUNDARY_CONDITIONS)) THEN
              RHS_DOMAIN_MAPPING=>RHS_VARIABLE%DOMAIN_MAPPING
              IF(ASSOCIATED(RHS_DOMAIN_MAPPING)) THEN
                CALL BOUNDARY_CONDITIONS_VARIABLE_GET(BOUNDARY_CONDITIONS,RHS_VARIABLE,RHS_BOUNDARY_CONDITIONS, &
                  & ERR,ERROR,*999)
                IF(ASSOCIATED(RHS_BOUNDARY_CONDITIONS)) THEN
                  !Get the equations residual vector
                  EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                  IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                    NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
                    IF(ASSOCIATED(NONLINEAR_MATRICES)) THEN
                      RESIDUAL_VECTOR=>NONLINEAR_MATRICES%RESIDUAL
                      IF(ASSOCIATED(RESIDUAL_VECTOR)) THEN
                        !Get mapping from equations rows to field dofs
                        NONLINEAR_MAPPING=>EQUATIONS_MAPPING%NONLINEAR_MAPPING
                        IF(ASSOCIATED(NONLINEAR_MAPPING)) THEN
                          DO equations_matrix_idx=1,NONLINEAR_MAPPING%NUMBER_OF_RESIDUAL_VARIABLES
                            RESIDUAL_VARIABLE=>NONLINEAR_MAPPING%JACOBIAN_TO_VAR_MAP(equations_matrix_idx)%VARIABLE
                            IF(ASSOCIATED(RESIDUAL_VARIABLE)) THEN
                              DO row_idx=1,EQUATIONS_MAPPING%NUMBER_OF_ROWS
                                variable_dof=RHS_MAPPING%EQUATIONS_ROW_TO_RHS_DOF_MAP(row_idx)
                                rhs_global_dof=RHS_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(variable_dof)
                                rhs_boundary_condition=RHS_BOUNDARY_CONDITIONS%DOF_TYPES(rhs_global_dof)
                                SELECT CASE(rhs_boundary_condition)
                                CASE(BOUNDARY_CONDITION_DOF_FREE)
                                  !Add residual to field value
                                  CALL DISTRIBUTED_VECTOR_VALUES_GET(RESIDUAL_VECTOR,row_idx,VALUE,ERR,ERROR,*999)
                                  CALL Field_ParameterSetUpdateLocalDOF(RHS_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                    & variable_dof,VALUE,ERR,ERROR,*999)
                                CASE(BOUNDARY_CONDITION_DOF_FIXED)
                                  !Do nothing
                                CASE(BOUNDARY_CONDITION_DOF_MIXED)
                                  CALL FlagError("Not implemented.",ERR,ERROR,*999)
                                CASE DEFAULT
                                  LOCAL_ERROR="The RHS variable boundary condition of "// &
                                    & TRIM(NUMBER_TO_VSTRING(rhs_boundary_condition,"*",ERR,ERROR))// &
                                    & " for RHS variable dof number "// &
                                    & TRIM(NUMBER_TO_VSTRING(variable_dof,"*",ERR,ERROR))//" is invalid."
                                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                                END SELECT
                              ENDDO
                            ELSE
                              CALL FlagError("Residual variable is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ENDDO !equations_matrix_idx
                        ELSE
                          CALL FlagError("Nonlinear mapping is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        CALL FlagError("Residual vector is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      CALL FlagError("Nonlinear matrices is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FlagError("Equations matrices is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("RHS boundary conditions variable is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("RHS variable domain mapping is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("Boundary conditions are not associated.",ERR,ERROR,*999)
            ENDIF
            CALL Field_ParameterSetUpdateStart(RHS_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
            CALL Field_ParameterSetUpdateFinish(RHS_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
          ELSE
            CALL FlagError("RHS variable field is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations mapping is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations set equations is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("EQUATIONS_SET_NONLINEAR_RHS_UPDATE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_NONLINEAR_RHS_UPDATE",ERR,ERROR)
    RETURN 1

  END SUBROUTINE EQUATIONS_SET_NONLINEAR_RHS_UPDATE

  !
  !================================================================================================================================
  !

  !>Set boundary conditions for an equation set according to the analytic equations. \see OPENCMISS::CMISSEquationsSetBoundaryConditionsAnalytic
  SUBROUTINE EQUATIONS_SET_BOUNDARY_CONDITIONS_ANALYTIC(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to set the analyticboundary conditions for.
    TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS !<A pointer to the boundary conditions to set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("EQUATIONS_SET_BOUNDARY_CONDITIONS_ANALYTIC",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(.NOT.ALLOCATED(EQUATIONS_SET%SPECIFICATION)) THEN
        CALL FlagError("Equations set specification is not allocated.",err,error,*999)
      ELSE IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<1) THEN
        CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
      END IF
      IF(EQUATIONS_SET%DEPENDENT%DEPENDENT_FINISHED) THEN
        IF(ASSOCIATED(EQUATIONS_SET%ANALYTIC)) THEN
          IF(EQUATIONS_SET%ANALYTIC%ANALYTIC_FINISHED) THEN
            SELECT CASE(EQUATIONS_SET%SPECIFICATION(1))
            CASE(EQUATIONS_SET_ELASTICITY_CLASS)
              CALL Elasticity_BoundaryConditionsAnalyticCalculate(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*999)
            CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
              CALL FluidMechanics_BoundaryConditionsAnalyticCalculate(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*999)
            CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
              CALL ClassicalField_BoundaryConditionsAnalyticCalculate(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*999)
            CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE(EQUATIONS_SET_MODAL_CLASS)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The first equations set specification of "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SPECIFICATION(1),"*", &
                & ERR,ERROR))//" is invalid."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          ELSE
            CALL FlagError("Equations set analytic has not been finished.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations set analytic is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations set dependent has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("EQUATIONS_SET_BOUNDARY_CONDITIONS_ANALYTIC")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_BOUNDARY_CONDITIONS_ANALYTIC",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_BOUNDARY_CONDITIONS_ANALYTIC

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating an equation set on a region. \see OPENCMISS::CMISSEquationsSetCreateStart
  SUBROUTINE EQUATIONS_SET_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to finish creating
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    
    ENTERS("EQUATIONS_SET_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(EQUATIONS_SET%EQUATIONS_SET_FINISHED) THEN
        CALL FlagError("Equations set has already been finished.",ERR,ERROR,*999)
      ELSE            
        EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_INITIAL_TYPE
        EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
        !Finish the equations set specific setup
        CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_GEOMETRY_TYPE
        EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
        !Finish the equations set specific geometry setup
        CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        !Finalise the setup
        CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        !Finish the equations set creation
        EQUATIONS_SET%EQUATIONS_SET_FINISHED=.TRUE.
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_CREATE_FINISH",ERR,ERROR)
    RETURN 1
   
  END SUBROUTINE EQUATIONS_SET_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Starts the process of creating an equations set defined by USER_NUMBER in the region identified by REGION. \see OPENCMISS::CMISSEquationsSetCreateStart
  !>Default values set for the EQUATIONS_SET's attributes are:
  !>- LINEARITY: 1 (EQUATIONS_SET_LINEAR)
  !>- TIME_DEPENDENCE: 1 (EQUATIONS_SET_STATIC)
  !>- SOLUTION_METHOD: 1 (EQUATIONS_SET_FEM_SOLUTION_METHOD)
  !>- GEOMETRY 
  !>- MATERIALS 
  !>- SOURCE 
  !>- DEPENDENT
  !>- ANALYTIC
  !>- FIXED_CONDITIONS 
  !>- EQUATIONS 
  SUBROUTINE EQUATIONS_SET_CREATE_START(USER_NUMBER,REGION,GEOM_FIBRE_FIELD,EQUATIONS_SET_SPECIFICATION,&
      & EQUATIONS_SET_FIELD_USER_NUMBER,EQUATIONS_SET_FIELD_FIELD,EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the equations set
    TYPE(REGION_TYPE), POINTER :: REGION !<A pointer to the region to create the equations set on
    TYPE(FIELD_TYPE), POINTER :: GEOM_FIBRE_FIELD !<A pointer to the either the geometry or, if appropriate, the fibre field for the equation set
    INTEGER(INTG), INTENT(IN) :: EQUATIONS_SET_SPECIFICATION(:) !<The equations set specification array to set
    INTEGER(INTG), INTENT(IN) :: EQUATIONS_SET_FIELD_USER_NUMBER !<The user number of the equations set field
    TYPE(FIELD_TYPE), POINTER :: EQUATIONS_SET_FIELD_FIELD !<On return, a pointer to the equations set field
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<On return, a pointer to the equations set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,equations_set_idx
    TYPE(EQUATIONS_SET_TYPE), POINTER :: NEW_EQUATIONS_SET
    TYPE(EQUATIONS_SET_PTR_TYPE), POINTER :: NEW_EQUATIONS_SETS(:)
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(REGION_TYPE), POINTER :: GEOM_FIBRE_FIELD_REGION,EQUATIONS_SET_FIELD_REGION
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR
    TYPE(EQUATIONS_SET_EQUATIONS_SET_FIELD_TYPE), POINTER :: EQUATIONS_EQUATIONS_SET_FIELD
    TYPE(FIELD_TYPE), POINTER :: FIELD

    NULLIFY(NEW_EQUATIONS_SET)
    NULLIFY(NEW_EQUATIONS_SETS)
    NULLIFY(EQUATIONS_EQUATIONS_SET_FIELD)

    ENTERS("EQUATIONS_SET_CREATE_START",ERR,ERROR,*997)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(REGION%EQUATIONS_SETS)) THEN
        CALL EQUATIONS_SET_USER_NUMBER_FIND(USER_NUMBER,REGION,NEW_EQUATIONS_SET,ERR,ERROR,*997)
        IF(ASSOCIATED(NEW_EQUATIONS_SET)) THEN
          LOCAL_ERROR="Equations set user number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
            & " has already been created on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*997)
        ELSE
          NULLIFY(NEW_EQUATIONS_SET)
          IF(ASSOCIATED(GEOM_FIBRE_FIELD)) THEN
            IF(GEOM_FIBRE_FIELD%FIELD_FINISHED) THEN
              IF(GEOM_FIBRE_FIELD%TYPE==FIELD_GEOMETRIC_TYPE.OR.GEOM_FIBRE_FIELD%TYPE==FIELD_FIBRE_TYPE) THEN
                GEOM_FIBRE_FIELD_REGION=>GEOM_FIBRE_FIELD%REGION
                IF(ASSOCIATED(GEOM_FIBRE_FIELD_REGION)) THEN
                  IF(GEOM_FIBRE_FIELD_REGION%USER_NUMBER==REGION%USER_NUMBER) THEN
                      IF(ASSOCIATED(EQUATIONS_SET_FIELD_FIELD)) THEN
                        !Check the equations set field has been finished
                        IF(EQUATIONS_SET_FIELD_FIELD%FIELD_FINISHED.eqv..TRUE.) THEN
                          !Check the user numbers match
                          IF(EQUATIONS_SET_FIELD_USER_NUMBER/=EQUATIONS_SET_FIELD_FIELD%USER_NUMBER) THEN
                            LOCAL_ERROR="The specified equations set field user number of "// &
                              & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                              & " does not match the user number of the specified equations set field of "// &
                              & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_FIELD_FIELD%USER_NUMBER,"*",ERR,ERROR))//"."
                            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                          ENDIF
                          EQUATIONS_SET_FIELD_REGION=>EQUATIONS_SET_FIELD_FIELD%REGION
                          IF(ASSOCIATED(EQUATIONS_SET_FIELD_REGION)) THEN                
                            !Check the field is defined on the same region as the equations set
                            IF(EQUATIONS_SET_FIELD_REGION%USER_NUMBER/=REGION%USER_NUMBER) THEN
                              LOCAL_ERROR="Invalid region setup. The specified equations set field was created on region no. "// &
                                & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_FIELD_REGION%USER_NUMBER,"*",ERR,ERROR))// &
                                & " and the specified equations set has been created on region number "// &
                                & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                            ENDIF
                            !Check the specified equations set field has the same decomposition as the geometric field
                            IF(ASSOCIATED(GEOM_FIBRE_FIELD)) THEN
                              IF(.NOT.ASSOCIATED(GEOM_FIBRE_FIELD%DECOMPOSITION,EQUATIONS_SET_FIELD_FIELD%DECOMPOSITION)) THEN
                                CALL FlagError("The specified equations set field does not have the same decomposition "// &
                                  & "as the geometric field for the specified equations set.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FlagError("The geom. field is not associated for the specified equations set.",ERR,ERROR,*999)
                            ENDIF
                              
                          ELSE
                            CALL FlagError("The specified equations set field region is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FlagError("The specified equations set field has not been finished.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        !Check the user number has not already been used for a field in this region.
                        NULLIFY(FIELD)
                        CALL FIELD_USER_NUMBER_FIND(EQUATIONS_SET_FIELD_USER_NUMBER,REGION,FIELD,ERR,ERROR,*999)
                        IF(ASSOCIATED(FIELD)) THEN
                          LOCAL_ERROR="The specified equations set field user number of "// &
                            & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                            & "has already been used to create a field on region number "// &
                            & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                        ENDIF
                      ENDIF
                      !Initalise equations set
                      CALL EQUATIONS_SET_INITIALISE(NEW_EQUATIONS_SET,ERR,ERROR,*999)
                      !Set default equations set values
                      NEW_EQUATIONS_SET%USER_NUMBER=USER_NUMBER
                      NEW_EQUATIONS_SET%GLOBAL_NUMBER=REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS+1
                      NEW_EQUATIONS_SET%EQUATIONS_SETS=>REGION%EQUATIONS_SETS
                      NEW_EQUATIONS_SET%REGION=>REGION
                      !Set the equations set class, type and subtype
                      CALL EquationsSet_SpecificationSet(NEW_EQUATIONS_SET,EQUATIONS_SET_SPECIFICATION,ERR,ERROR,*999)
                      NEW_EQUATIONS_SET%EQUATIONS_SET_FINISHED=.FALSE.
                      !Initialise the setup
                      CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
                      EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_INITIAL_TYPE
                      EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
                      !Here, we get a pointer to the equations_set_field; default is null
                      EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=EQUATIONS_SET_FIELD_USER_NUMBER
                      EQUATIONS_SET_SETUP_INFO%FIELD=>EQUATIONS_SET_FIELD_FIELD
                      !Start equations set specific setup
                      CALL EQUATIONS_SET_SETUP(NEW_EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
                      CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
                      !Set up the equations set geometric fields
                      CALL EQUATIONS_SET_GEOMETRY_INITIALISE(NEW_EQUATIONS_SET,ERR,ERROR,*999)
                      IF(GEOM_FIBRE_FIELD%TYPE==FIELD_GEOMETRIC_TYPE) THEN
                        NEW_EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD=>GEOM_FIBRE_FIELD
                        NULLIFY(NEW_EQUATIONS_SET%GEOMETRY%FIBRE_FIELD)
                      ELSE
                        NEW_EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD=>GEOM_FIBRE_FIELD%GEOMETRIC_FIELD
                        NEW_EQUATIONS_SET%GEOMETRY%FIBRE_FIELD=>GEOM_FIBRE_FIELD
                      ENDIF
                      EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_GEOMETRY_TYPE
                      EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
                      EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=GEOM_FIBRE_FIELD%USER_NUMBER
                      EQUATIONS_SET_SETUP_INFO%FIELD=>GEOM_FIBRE_FIELD
                      !Set up equations set specific geometry
                      CALL EQUATIONS_SET_SETUP(NEW_EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
                      !Finalise the setup
                      CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
                      !Add new equations set into list of equations set in the region
                      ALLOCATE(NEW_EQUATIONS_SETS(REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS+1),STAT=ERR)
                      IF(ERR/=0) CALL FlagError("Could not allocate new equations sets.",ERR,ERROR,*999)
                      DO equations_set_idx=1,REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS
                        NEW_EQUATIONS_SETS(equations_set_idx)%PTR=>REGION%EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR
                      ENDDO !equations_set_idx
                      NEW_EQUATIONS_SETS(REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS+1)%PTR=>NEW_EQUATIONS_SET
                      IF(ASSOCIATED(REGION%EQUATIONS_SETS%EQUATIONS_SETS)) DEALLOCATE(REGION%EQUATIONS_SETS%EQUATIONS_SETS)
                      REGION%EQUATIONS_SETS%EQUATIONS_SETS=>NEW_EQUATIONS_SETS
                      REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS=REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS+1
                      EQUATIONS_SET=>NEW_EQUATIONS_SET
                      EQUATIONS_EQUATIONS_SET_FIELD=>EQUATIONS_SET%EQUATIONS_SET_FIELD
                      !\todo check pointer setup
                      IF(EQUATIONS_EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_AUTO_CREATED) THEN
                        EQUATIONS_SET_FIELD_FIELD=>EQUATIONS_SET%EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_FIELD
                      ELSE
                        EQUATIONS_SET%EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_FIELD=>EQUATIONS_SET_FIELD_FIELD
                      ENDIF
                  ELSE
                    LOCAL_ERROR="The geometric field region and the specified region do not match. "// &
                      & "The geometric field was created on region number "// &
                      & TRIM(NUMBER_TO_VSTRING(GEOM_FIBRE_FIELD_REGION%USER_NUMBER,"*",ERR,ERROR))// &
                      & " and the specified region number is "// &
                      & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                    CALL FlagError(LOCAL_ERROR,ERR,ERROR,*997)
                  ENDIF
                ELSE
                  CALL FlagError("The specified geometric fields region is not associated.",ERR,ERROR,*997)
                ENDIF
              ELSE
                CALL FlagError("The specified geometric field is not a geometric or fibre field.",ERR,ERROR,*997)
              ENDIF
            ELSE
              CALL FlagError("The specified geometric field is not finished.",ERR,ERROR,*997)
            ENDIF
          ELSE
            CALL FlagError("The specified geometric field is not associated.",ERR,ERROR,*997)
          ENDIF
        ENDIF
      ELSE
        LOCAL_ERROR="The equations sets on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))// &
          & " are not associated."
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*997)
      ENDIF
    ELSE
      CALL FlagError("Region is not associated.",ERR,ERROR,*997)
    ENDIF
    
    EXITS("EQUATIONS_SET_CREATE_START")
    RETURN
999 IF(ASSOCIATED(NEW_EQUATIONS_SET))CALL EQUATIONS_SET_FINALISE(NEW_EQUATIONS_SET,DUMMY_ERR,DUMMY_ERROR,*998)
998 IF(ASSOCIATED(NEW_EQUATIONS_SETS)) DEALLOCATE(NEW_EQUATIONS_SETS)
997 ERRORSEXITS("EQUATIONS_SET_CREATE_START",ERR,ERROR)
    RETURN 1   
  END SUBROUTINE EQUATIONS_SET_CREATE_START
  
  !
  !================================================================================================================================
  !

  !>Destroys an equations set identified by a user number on the give region and deallocates all memory. \see OPENCMISS::CMISSEquationsSetDestroy
  SUBROUTINE EQUATIONS_SET_DESTROY_NUMBER(USER_NUMBER,REGION,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the equations set to destroy
    TYPE(REGION_TYPE), POINTER :: REGION !<The region of the equations set to destroy
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: equations_set_idx,equations_set_position
    LOGICAL :: FOUND
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(EQUATIONS_SET_PTR_TYPE), POINTER :: NEW_EQUATIONS_SETS(:)

    NULLIFY(NEW_EQUATIONS_SETS)

    ENTERS("EQUATIONS_SET_DESTROY_NUMBER",ERR,ERROR,*999)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(REGION%EQUATIONS_SETS)) THEN
        
        !Find the equations set identified by the user number
        FOUND=.FALSE.
        equations_set_position=0
        DO WHILE(equations_set_position<REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS.AND..NOT.FOUND)
          equations_set_position=equations_set_position+1
          IF(REGION%EQUATIONS_SETS%EQUATIONS_SETS(equations_set_position)%PTR%USER_NUMBER==USER_NUMBER)FOUND=.TRUE.
        ENDDO
        
        IF(FOUND) THEN
          
          EQUATIONS_SET=>REGION%EQUATIONS_SETS%EQUATIONS_SETS(equations_set_position)%PTR
          
          !Destroy all the equations set components
          CALL EQUATIONS_SET_FINALISE(EQUATIONS_SET,ERR,ERROR,*999)
          
          !Remove the equations set from the list of equations set
          IF(REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS>1) THEN
            ALLOCATE(NEW_EQUATIONS_SETS(REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS-1),STAT=ERR)
            IF(ERR/=0) CALL FlagError("Could not allocate new equations sets.",ERR,ERROR,*999)
            DO equations_set_idx=1,REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS
              IF(equations_set_idx<equations_set_position) THEN
                NEW_EQUATIONS_SETS(equations_set_idx)%PTR=>REGION%EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR
              ELSE IF(equations_set_idx>equations_set_position) THEN
                REGION%EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR%GLOBAL_NUMBER=REGION%EQUATIONS_SETS% &
                  & EQUATIONS_SETS(equations_set_idx)%PTR%GLOBAL_NUMBER-1
                NEW_EQUATIONS_SETS(equations_set_idx-1)%PTR=>REGION%EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR
              ENDIF
            ENDDO !equations_set_idx
            IF(ASSOCIATED(REGION%EQUATIONS_SETS%EQUATIONS_SETS)) DEALLOCATE(REGION%EQUATIONS_SETS%EQUATIONS_SETS)
            REGION%EQUATIONS_SETS%EQUATIONS_SETS=>NEW_EQUATIONS_SETS
            REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS=REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS-1
          ELSE
            DEALLOCATE(REGION%EQUATIONS_SETS%EQUATIONS_SETS)
            REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS=0
          ENDIF
          
        ELSE
          LOCAL_ERROR="Equations set number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
            & " has not been created on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ELSE
        LOCAL_ERROR="The equations sets on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))// &
          & " are not associated."
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Region is not associated.",ERR,ERROR,*998)
    ENDIF    

    EXITS("EQUATIONS_SET_DESTROY_NUMBER")
    RETURN
999 IF(ASSOCIATED(NEW_EQUATIONS_SETS)) DEALLOCATE(NEW_EQUATIONS_SETS)
998 ERRORSEXITS("EQUATIONS_SET_DESTROY_NUMBER",ERR,ERROR)
    RETURN 1   
  END SUBROUTINE EQUATIONS_SET_DESTROY_NUMBER
  
  !
  !================================================================================================================================
  !

  !>Destroys an equations set identified by a pointer and deallocates all memory. \see OPENCMISS::CMISSEquationsSetDestroy
  SUBROUTINE EQUATIONS_SET_DESTROY(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to destroy
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: equations_set_idx,equations_set_position
    TYPE(EQUATIONS_SETS_TYPE), POINTER :: EQUATIONS_SETS
    TYPE(EQUATIONS_SET_PTR_TYPE), POINTER :: NEW_EQUATIONS_SETS(:)

    NULLIFY(NEW_EQUATIONS_SETS)

    ENTERS("EQUATIONS_SET_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS_SETS=>EQUATIONS_SET%EQUATIONS_SETS
      IF(ASSOCIATED(EQUATIONS_SETS)) THEN
        equations_set_position=EQUATIONS_SET%GLOBAL_NUMBER

        !Destroy all the equations set components
        CALL EQUATIONS_SET_FINALISE(EQUATIONS_SET,ERR,ERROR,*999)
        
        !Remove the equations set from the list of equations set
        IF(EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS>1) THEN
          ALLOCATE(NEW_EQUATIONS_SETS(EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS-1),STAT=ERR)
          IF(ERR/=0) CALL FlagError("Could not allocate new equations sets.",ERR,ERROR,*999)
          DO equations_set_idx=1,EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS
            IF(equations_set_idx<equations_set_position) THEN
              NEW_EQUATIONS_SETS(equations_set_idx)%PTR=>EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR
            ELSE IF(equations_set_idx>equations_set_position) THEN
              EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR%GLOBAL_NUMBER=EQUATIONS_SETS% &
                & EQUATIONS_SETS(equations_set_idx)%PTR%GLOBAL_NUMBER-1
              NEW_EQUATIONS_SETS(equations_set_idx-1)%PTR=>EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR
            ENDIF
          ENDDO !equations_set_idx
          IF(ASSOCIATED(EQUATIONS_SETS%EQUATIONS_SETS)) DEALLOCATE(EQUATIONS_SETS%EQUATIONS_SETS)
          EQUATIONS_SETS%EQUATIONS_SETS=>NEW_EQUATIONS_SETS
          EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS=EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS-1
        ELSE
          DEALLOCATE(EQUATIONS_SETS%EQUATIONS_SETS)
          EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS=0
        ENDIF
        
      ELSE
        CALL FlagError("Equations set equations set is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*998)
    ENDIF    

    EXITS("EQUATIONS_SET_DESTROY")
    RETURN
999 IF(ASSOCIATED(NEW_EQUATIONS_SETS)) DEALLOCATE(NEW_EQUATIONS_SETS)
998 ERRORSEXITS("EQUATIONS_SET_DESTROY",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_DESTROY
  
  !
  !================================================================================================================================
  !

  !>Finalise the equations set and deallocate all memory.
  SUBROUTINE EQUATIONS_SET_FINALISE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to finalise.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      CALL EQUATIONS_SET_GEOMETRY_FINALISE(EQUATIONS_SET%GEOMETRY,ERR,ERROR,*999)
      CALL EQUATIONS_SET_DEPENDENT_FINALISE(EQUATIONS_SET%DEPENDENT,ERR,ERROR,*999)
      CALL EQUATIONS_SET_INDEPENDENT_FINALISE(EQUATIONS_SET%INDEPENDENT,ERR,ERROR,*999)
      CALL EQUATIONS_SET_MATERIALS_FINALISE(EQUATIONS_SET%MATERIALS,ERR,ERROR,*999)
      CALL EQUATIONS_SET_SOURCE_FINALISE(EQUATIONS_SET%SOURCE,ERR,ERROR,*999)
      CALL EQUATIONS_SET_ANALYTIC_FINALISE(EQUATIONS_SET%ANALYTIC,ERR,ERROR,*999)
      CALL EQUATIONS_SET_EQUATIONS_SET_FIELD_FINALISE(EQUATIONS_SET%EQUATIONS_SET_FIELD,ERR,ERROR,*999)
      CALL EquationsSet_DerivedFinalise(EQUATIONS_SET%derived,ERR,ERROR,*999)
      IF(ASSOCIATED(EQUATIONS_SET%EQUATIONS)) CALL EQUATIONS_DESTROY(EQUATIONS_SET%EQUATIONS,ERR,ERROR,*999)
      IF(ALLOCATED(EQUATIONS_SET%SPECIFICATION)) DEALLOCATE(EQUATIONS_SET%SPECIFICATION)
      DEALLOCATE(EQUATIONS_SET)
    ENDIF
       
    EXITS("EQUATIONS_SET_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_FINALISE",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_FINALISE

  !
  !================================================================================================================================
  !

  !>Calculates the element stiffness matries and rhs vector for the given element number for a finite element equations set.
  SUBROUTINE EQUATIONS_SET_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set
    INTEGER(INTG), INTENT(IN) :: ELEMENT_NUMBER !<The element number to calcualte
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code 
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: matrix_idx
    TYPE(ELEMENT_MATRIX_TYPE), POINTER :: ELEMENT_MATRIX
    TYPE(ELEMENT_VECTOR_TYPE), POINTER :: ELEMENT_VECTOR
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_DYNAMIC_TYPE), POINTER :: DYNAMIC_MATRICES
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: LINEAR_MATRICES
    TYPE(EQUATIONS_MATRICES_RHS_TYPE), POINTER :: RHS_VECTOR
    TYPE(EQUATIONS_MATRICES_SOURCE_TYPE), POINTER :: SOURCE_VECTOR
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
#ifdef TAUPROF
    CALL TAU_STATIC_PHASE_START("EQUATIONS_SET_FINITE_ELEMENT_CALCULATE()")
#endif

    ENTERS("EQUATIONS_SET_FINITE_ELEMENT_CALCULATE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(.NOT.ALLOCATED(EQUATIONS_SET%SPECIFICATION)) THEN
        CALL FlagError("Equations set specification is not allocated.",err,error,*999)
      ELSE IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<1) THEN
        CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
      END IF
      SELECT CASE(EQUATIONS_SET%SPECIFICATION(1))
      CASE(EQUATIONS_SET_ELASTICITY_CLASS)
        CALL ELASTICITY_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
       CALL FLUID_MECHANICS_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
        CALL CLASSICAL_FIELD_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_FITTING_CLASS)
        CALL FITTING_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
        IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<2) THEN
          CALL FlagError("Equations set specification must have at least two entries for a bioelectrics equation class.", &
            & err,error,*999)
        END IF
        IF(EQUATIONS_SET%SPECIFICATION(2) == EQUATIONS_SET_MONODOMAIN_STRANG_SPLITTING_EQUATION_TYPE) THEN
          CALL Monodomain_FiniteElementCalculate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
        ELSE
          CALL BIOELECTRIC_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
        END IF
      CASE(EQUATIONS_SET_MODAL_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
       CALL MULTI_PHYSICS_FINITE_ELEMENT_CALCULATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The first equations set specification of "// &
          & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SPECIFICATION(1),"*",ERR,ERROR))//" is not valid."
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN
        IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_ELEMENT_MATRIX_OUTPUT) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Finite element stiffness matrices:",ERR,ERROR,*999)
            CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Element number = ",ELEMENT_NUMBER,ERR,ERROR,*999)
            DYNAMIC_MATRICES=>EQUATIONS_MATRICES%DYNAMIC_MATRICES
            IF(ASSOCIATED(DYNAMIC_MATRICES)) THEN
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Dynamic matrices:",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Number of element matrices = ",DYNAMIC_MATRICES% &
                & NUMBER_OF_DYNAMIC_MATRICES,ERR,ERROR,*999)
              DO matrix_idx=1,DYNAMIC_MATRICES%NUMBER_OF_DYNAMIC_MATRICES
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Element matrix : ",matrix_idx,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update matrix = ",DYNAMIC_MATRICES%MATRICES(matrix_idx)%PTR% &
                  & UPDATE_MATRIX,ERR,ERROR,*999)
                IF(DYNAMIC_MATRICES%MATRICES(matrix_idx)%PTR%UPDATE_MATRIX) THEN
                  ELEMENT_MATRIX=>DYNAMIC_MATRICES%MATRICES(matrix_idx)%PTR%ELEMENT_MATRIX
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_MATRIX%NUMBER_OF_ROWS,ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of columns = ",ELEMENT_MATRIX%NUMBER_OF_COLUMNS, &
                    & ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_MATRIX%MAX_NUMBER_OF_ROWS, &
                    & ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of columns = ",ELEMENT_MATRIX% &
                    & MAX_NUMBER_OF_COLUMNS,ERR,ERROR,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,8,8,ELEMENT_MATRIX%ROW_DOFS, &
                    & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX% &
                    & COLUMN_DOFS,'("  Column dofs  :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                  CALL WRITE_STRING_MATRIX(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,1,1,ELEMENT_MATRIX% &
                    & NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX%MATRIX(1:ELEMENT_MATRIX%NUMBER_OF_ROWS,1:ELEMENT_MATRIX% &
                    & NUMBER_OF_COLUMNS),WRITE_STRING_MATRIX_NAME_AND_INDICES,'("  Matrix','(",I2,",:)',' :",8(X,E13.6))', &
                    & '(16X,8(X,E13.6))',ERR,ERROR,*999)
                ENDIF
              ENDDO !matrix_idx
            ENDIF
            LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
            IF(ASSOCIATED(LINEAR_MATRICES)) THEN
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Linear matrices:",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Number of element matrices = ",LINEAR_MATRICES% &
                & NUMBER_OF_LINEAR_MATRICES,ERR,ERROR,*999)
              DO matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Element matrix : ",matrix_idx,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update matrix = ",LINEAR_MATRICES%MATRICES(matrix_idx)%PTR% &
                  & UPDATE_MATRIX,ERR,ERROR,*999)
                IF(LINEAR_MATRICES%MATRICES(matrix_idx)%PTR%UPDATE_MATRIX) THEN
                  ELEMENT_MATRIX=>LINEAR_MATRICES%MATRICES(matrix_idx)%PTR%ELEMENT_MATRIX
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_MATRIX%NUMBER_OF_ROWS,ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of columns = ",ELEMENT_MATRIX%NUMBER_OF_COLUMNS, &
                    & ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_MATRIX%MAX_NUMBER_OF_ROWS, &
                    & ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of columns = ",ELEMENT_MATRIX% &
                    & MAX_NUMBER_OF_COLUMNS,ERR,ERROR,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,8,8,ELEMENT_MATRIX%ROW_DOFS, &
                    & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX% &
                    & COLUMN_DOFS,'("  Column dofs  :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                  CALL WRITE_STRING_MATRIX(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,1,1,ELEMENT_MATRIX% &
                    & NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX%MATRIX(1:ELEMENT_MATRIX%NUMBER_OF_ROWS,1:ELEMENT_MATRIX% &
                    & NUMBER_OF_COLUMNS),WRITE_STRING_MATRIX_NAME_AND_INDICES,'("  Matrix','(",I2,",:)',' :",8(X,E13.6))', &
                    & '(16X,8(X,E13.6))',ERR,ERROR,*999)
                ENDIF
              ENDDO !matrix_idx
            ENDIF
            RHS_VECTOR=>EQUATIONS_MATRICES%RHS_VECTOR
            IF(ASSOCIATED(RHS_VECTOR)) THEN
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Element RHS vector :",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update vector = ",RHS_VECTOR%UPDATE_VECTOR,ERR,ERROR,*999)
              IF(RHS_VECTOR%UPDATE_VECTOR) THEN
                ELEMENT_VECTOR=>RHS_VECTOR%ELEMENT_VECTOR
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_VECTOR%NUMBER_OF_ROWS,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_VECTOR%MAX_NUMBER_OF_ROWS, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%ROW_DOFS, &
                  & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%VECTOR, &
                  & '("  Vector(:):",8(X,E13.6))','(16X,8(X,E13.6))',ERR,ERROR,*999)
              ENDIF
            ENDIF
            SOURCE_VECTOR=>EQUATIONS_MATRICES%SOURCE_VECTOR
            IF(ASSOCIATED(SOURCE_VECTOR)) THEN
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Element source vector :",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update vector = ",SOURCE_VECTOR%UPDATE_VECTOR,ERR,ERROR,*999)
              IF(SOURCE_VECTOR%UPDATE_VECTOR) THEN
                ELEMENT_VECTOR=>SOURCE_VECTOR%ELEMENT_VECTOR
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_VECTOR%NUMBER_OF_ROWS,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_VECTOR%MAX_NUMBER_OF_ROWS, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%ROW_DOFS, &
                  & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%VECTOR, &
                  & '("  Vector(:):",8(X,E13.6))','(16X,8(X,E13.6))',ERR,ERROR,*999)
              ENDIF
            ENDIF
          ELSE
            CALL FlagError("Equation matrices is not associated.",ERR,ERROR,*999)
          ENDIF
        ENDIF
      ELSE
        CALL FlagError("Equations is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF    

#ifdef TAUPROF
    CALL TAU_STATIC_PHASE_STOP("EQUATIONS_SET_FINITE_ELEMENT_CALCULATE()")
#endif
       
    EXITS("EQUATIONS_SET_FINITE_ELEMENT_CALCULATE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_FINITE_ELEMENT_CALCULATE",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_FINITE_ELEMENT_CALCULATE

  !
  !================================================================================================================================
  !

  !>Evaluates the element Jacobian for the given element number for a finite element equations set.
  SUBROUTINE EquationsSet_FiniteElementJacobianEvaluate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set
    INTEGER(INTG), INTENT(IN) :: ELEMENT_NUMBER !<The element number to evaluate the Jacobian for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code 
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: matrix_idx
    TYPE(ELEMENT_MATRIX_TYPE), POINTER :: ELEMENT_MATRIX
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    ENTERS("EquationsSet_FiniteElementJacobianEvaluate",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(.NOT.ALLOCATED(EQUATIONS_SET%SPECIFICATION)) THEN
        CALL FlagError("Equations set specification is not allocated.",err,error,*999)
      ELSE IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<1) THEN
        CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
      END IF
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN
        EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
        IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
          NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
          IF(ASSOCIATED(NONLINEAR_MATRICES)) THEN
            DO matrix_idx=1,NONLINEAR_MATRICES%NUMBER_OF_JACOBIANS
              SELECT CASE(NONLINEAR_MATRICES%JACOBIANS(matrix_idx)%PTR%JACOBIAN_CALCULATION_TYPE)
              CASE(EQUATIONS_JACOBIAN_ANALYTIC_CALCULATED)
                ! None of these routines currently support calculating off diagonal terms for coupled problems,
                ! but when one does we will have to pass through the matrix_idx parameter
                IF(matrix_idx>1) THEN
                  CALL FlagError("Analytic off-diagonal Jacobian calculation not implemented.",ERR,ERROR,*999)
                END IF
                SELECT CASE(EQUATIONS_SET%SPECIFICATION(1))
                CASE(EQUATIONS_SET_ELASTICITY_CLASS)
                  CALL ELASTICITY_FINITE_ELEMENT_JACOBIAN_EVALUATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
                CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
                  CALL FluidMechanics_FiniteElementJacobianEvaluate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
                CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
                  CALL FlagError("Not implemented.",ERR,ERROR,*999)
                CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
                  CALL ClassicalField_FiniteElementJacobianEvaluate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
                CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
                  CALL FlagError("Not implemented.",ERR,ERROR,*999)
                CASE(EQUATIONS_SET_MODAL_CLASS)
                  CALL FlagError("Not implemented.",ERR,ERROR,*999)
                CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
                  CALL MultiPhysics_FiniteElementJacobianEvaluate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
                CASE DEFAULT
                  LOCAL_ERROR="The first equations set specification of"// &
                    & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SPECIFICATION(1),"*", &
                    & ERR,ERROR))//" is not valid."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                END SELECT
              CASE(EQUATIONS_JACOBIAN_FINITE_DIFFERENCE_CALCULATED)
                CALL EquationsSet_FiniteElementJacobianEvaluateFD(EQUATIONS_SET,ELEMENT_NUMBER,matrix_idx,ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="Jacobian calculation type "//TRIM(NUMBER_TO_VSTRING(NONLINEAR_MATRICES%JACOBIANS(matrix_idx)%PTR% &
                  & JACOBIAN_CALCULATION_TYPE,"*",ERR,ERROR))//" is not valid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            END DO
          ELSE
            CALL FlagError("Equations nonlinear matrices is not associated.",ERR,ERROR,*999)
          END IF
        ELSE
          CALL FlagError("Equations matrices is not associated.",ERR,ERROR,*999)
        END IF
        IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_ELEMENT_MATRIX_OUTPUT) THEN
          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Finite element Jacobian matrix:",ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Element number = ",ELEMENT_NUMBER,ERR,ERROR,*999)
          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Element Jacobian:",ERR,ERROR,*999)
          DO matrix_idx=1,NONLINEAR_MATRICES%NUMBER_OF_JACOBIANS
            CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Jacobian number = ",matrix_idx,ERR,ERROR,*999)
            CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update Jacobian = ",NONLINEAR_MATRICES%JACOBIANS(matrix_idx)%PTR% &
              & UPDATE_JACOBIAN,ERR,ERROR,*999)
            IF(NONLINEAR_MATRICES%JACOBIANS(matrix_idx)%PTR%UPDATE_JACOBIAN) THEN
              ELEMENT_MATRIX=>NONLINEAR_MATRICES%JACOBIANS(matrix_idx)%PTR%ELEMENT_JACOBIAN
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_MATRIX%NUMBER_OF_ROWS,ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of columns = ",ELEMENT_MATRIX%NUMBER_OF_COLUMNS, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_MATRIX%MAX_NUMBER_OF_ROWS, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of columns = ",ELEMENT_MATRIX% &
                & MAX_NUMBER_OF_COLUMNS,ERR,ERROR,*999)
              CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,8,8,ELEMENT_MATRIX%ROW_DOFS, &
                & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
              CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX% &
                & COLUMN_DOFS,'("  Column dofs  :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
              CALL WRITE_STRING_MATRIX(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,1,1,ELEMENT_MATRIX% &
                & NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX%MATRIX(1:ELEMENT_MATRIX%NUMBER_OF_ROWS,1:ELEMENT_MATRIX% &
                & NUMBER_OF_COLUMNS),WRITE_STRING_MATRIX_NAME_AND_INDICES,'("  Matrix','(",I2,",:)',' :",8(X,E13.6))', &
                & '(16X,8(X,E13.6))',ERR,ERROR,*999)
!!TODO: Write out the element residual???
            END IF
          END DO
        END IF
      ELSE
        CALL FlagError("Equations is not associated.",ERR,ERROR,*999)
      END IF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    END IF

    EXITS("EquationsSet_FiniteElementJacobianEvaluate")
    RETURN
999 ERRORSEXITS("EquationsSet_FiniteElementJacobianEvaluate",ERR,ERROR)
    RETURN 1

  END SUBROUTINE EquationsSet_FiniteElementJacobianEvaluate

  !
  !================================================================================================================================
  !

  !>Evaluates the element Jacobian matrix entries using finite differencing for a general finite element equations set.
  SUBROUTINE EquationsSet_FiniteElementJacobianEvaluateFD(equationsSet,elementNumber,jacobianNumber,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet  !<A pointer to the equations set to evaluate the element Jacobian for
    INTEGER(INTG), INTENT(IN) :: elementNumber  !<The element number to calculate the Jacobian for
    INTEGER(INTG), INTENT(IN) :: jacobianNumber  !<The Jacobian number to calculate when there are coupled problems
    INTEGER(INTG), INTENT(OUT) :: err  !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error  !<The error string
    !Local Variables
    TYPE(EQUATIONS_TYPE), POINTER :: equations
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: equationsMatrices
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: nonlinearMatrices
    TYPE(EQUATIONS_MAPPING_NONLINEAR_TYPE), POINTER :: nonlinearMapping
    TYPE(DOMAIN_ELEMENTS_TYPE), POINTER :: elementsTopology
    TYPE(BASIS_TYPE), POINTER :: basis
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: parameters
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: rowVariable,columnVariable
    TYPE(ELEMENT_VECTOR_TYPE) :: elementVector
    INTEGER(INTG) :: componentIdx,localNy,version,derivativeIdx,derivative,nodeIdx,node,column
    INTEGER(INTG) :: componentInterpolationType
    INTEGER(INTG) :: numberOfRows
    REAL(DP) :: delta,origDepVar

    ENTERS("EquationsSet_FiniteElementJacobianEvaluateFD",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      equations=>equationsSet%EQUATIONS
      IF(ASSOCIATED(equations)) THEN
        equationsMatrices=>equations%EQUATIONS_MATRICES
        nonlinearMatrices=>equationsMatrices%NONLINEAR_MATRICES
        nonlinearMapping=>equations%EQUATIONS_MAPPING%NONLINEAR_MAPPING
        ! The first residual variable is always the row variable, which is the variable the
        ! residual is calculated for
        rowVariable=>nonlinearMapping%RESIDUAL_VARIABLES(1)%PTR
        ! For coupled problems this routine will be called multiple times if multiple Jacobians use finite
        ! differencing, so make sure we only calculate the residual vector once, to save time and because
        ! it would otherwise add together
        IF(nonlinearMatrices%ELEMENT_RESIDUAL_CALCULATED/=elementNumber) THEN
          CALL EquationsSet_FiniteElementResidualEvaluate(equationsSet,elementNumber,err,error,*999)
        END IF
        ! make a temporary copy of the unperturbed residuals
        elementVector=nonlinearMatrices%ELEMENT_RESIDUAL
        IF(jacobianNumber<=nonlinearMatrices%NUMBER_OF_JACOBIANS) THEN
          ! For coupled nonlinear problems there will be multiple Jacobians
          ! For this equations set, we calculate the residual for the row variable
          ! while pertubing parameters from the column variable.
          ! For non coupled problems these two variables will be the same
          columnVariable=>nonlinearMapping%RESIDUAL_VARIABLES(jacobianNumber)%PTR
          parameters=>columnVariable%PARAMETER_SETS%PARAMETER_SETS(FIELD_VALUES_SET_TYPE)%PTR%PARAMETERS  ! vector of dependent variables, basically
          numberOfRows=nonlinearMatrices%JACOBIANS(jacobianNumber)%PTR%ELEMENT_JACOBIAN%NUMBER_OF_ROWS
          IF(numberOfRows/=nonlinearMatrices%ELEMENT_RESIDUAL%NUMBER_OF_ROWS) THEN
            CALL FlagError("Element matrix number of rows does not match element residual vector size.",err,error,*999)
          END IF
          ! determine step size
          CALL DistributedVector_L2Norm(parameters,delta,err,error,*999)
          delta=(1.0_DP+delta)*1E-7_DP
          ! the actual finite differencing algorithm is about 4 lines but since the parameters are all
          ! distributed out, have to use proper field accessing routines..
          ! so let's just loop over component, node/el, derivative
          column=0  ! element jacobian matrix column number
          DO componentIdx=1,columnVariable%NUMBER_OF_COMPONENTS
            elementsTopology=>columnVariable%COMPONENTS(componentIdx)%DOMAIN%TOPOLOGY%ELEMENTS
            componentInterpolationType=columnVariable%COMPONENTS(componentIdx)%INTERPOLATION_TYPE
            SELECT CASE (componentInterpolationType)
            CASE (FIELD_NODE_BASED_INTERPOLATION)
              basis=>elementsTopology%ELEMENTS(elementNumber)%BASIS
              DO nodeIdx=1,basis%NUMBER_OF_NODES
                node=elementsTopology%ELEMENTS(elementNumber)%ELEMENT_NODES(nodeIdx)
                DO derivativeIdx=1,basis%NUMBER_OF_DERIVATIVES(nodeIdx)
                  derivative=elementsTopology%ELEMENTS(elementNumber)%ELEMENT_DERIVATIVES(derivativeIdx,nodeIdx)
                  version=elementsTopology%ELEMENTS(elementNumber)%elementVersions(derivativeIdx,nodeIdx)
                  localNy=columnVariable%COMPONENTS(componentIdx)%PARAM_TO_DOF_MAP%NODE_PARAM2DOF_MAP%NODES(node)% &
                    & DERIVATIVES(derivative)%VERSIONS(version)
                  ! one-sided finite difference
                  CALL DISTRIBUTED_VECTOR_VALUES_GET(parameters,localNy,origDepVar,err,error,*999)
                  CALL DISTRIBUTED_VECTOR_VALUES_SET(parameters,localNy,origDepVar+delta,err,error,*999)
                  nonlinearMatrices%ELEMENT_RESIDUAL%VECTOR=0.0_DP ! must remember to flush existing results, otherwise they're added
                  CALL EquationsSet_FiniteElementResidualEvaluate(equationsSet,elementNumber,err,error,*999)
                  CALL DISTRIBUTED_VECTOR_VALUES_SET(parameters,localNy,origDepVar,err,error,*999)
                  column=column+1
                  nonlinearMatrices%JACOBIANS(jacobianNumber)%PTR%ELEMENT_JACOBIAN%MATRIX(1:numberOfRows,column)= &
                      & (nonlinearMatrices%ELEMENT_RESIDUAL%VECTOR(1:numberOfRows)-elementVector%VECTOR(1:numberOfRows))/delta
                ENDDO !derivativeIdx
              ENDDO !nodeIdx
            CASE (FIELD_ELEMENT_BASED_INTERPOLATION)
              localNy=columnVariable%COMPONENTS(componentIdx)%PARAM_TO_DOF_MAP%ELEMENT_PARAM2DOF_MAP%ELEMENTS(elementNumber)
              ! one-sided finite difference
              CALL DISTRIBUTED_VECTOR_VALUES_GET(parameters,localNy,origDepVar,err,error,*999)
              CALL DISTRIBUTED_VECTOR_VALUES_SET(parameters,localNy,origDepVar+delta,err,error,*999)
              nonlinearMatrices%ELEMENT_RESIDUAL%VECTOR=0.0_DP ! must remember to flush existing results, otherwise they're added
              CALL EquationsSet_FiniteElementResidualEvaluate(equationsSet,elementNumber,err,error,*999)
              CALL DISTRIBUTED_VECTOR_VALUES_SET(parameters,localNy,origDepVar,err,error,*999)
              column=column+1
              nonlinearMatrices%JACOBIANS(jacobianNumber)%PTR%ELEMENT_JACOBIAN%MATRIX(1:numberOfRows,column)= &
                  & (nonlinearMatrices%ELEMENT_RESIDUAL%VECTOR(1:numberOfRows)-elementVector%VECTOR(1:numberOfRows))/delta
            CASE DEFAULT
              CALL FlagError("Unsupported type of interpolation.",err,error,*999)
            END SELECT
          END DO
          ! put the original residual back in
          nonlinearMatrices%ELEMENT_RESIDUAL=elementVector
        ELSE
          CALL FlagError("Invalid Jacobian number of "//TRIM(NUMBER_TO_VSTRING(jacobianNumber,"*",err,error))// &
            & ". The number should be <= "//TRIM(NUMBER_TO_VSTRING(nonlinearMatrices%NUMBER_OF_JACOBIANS,"*",err,error))// &
            & ".",err,error,*999)
        END IF
      ELSE
        CALL FlagError("Equations set equations is not associated.",err,error,*999)
      END IF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    END IF

    EXITS("EquationsSet_FiniteElementJacobianEvaluateFD")
    RETURN
999 ERRORS("EquationsSet_FiniteElementJacobianEvaluateFD",err,error)
    EXITS("EquationsSet_FiniteElementJacobianEvaluateFD")
    RETURN 1
  END SUBROUTINE EquationsSet_FiniteElementJacobianEvaluateFD

  !
  !================================================================================================================================
  !

  !>Evaluates the element residual and rhs vector for the given element number for a finite element equations set.
  SUBROUTINE EquationsSet_FiniteElementResidualEvaluate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set
    INTEGER(INTG), INTENT(IN) :: ELEMENT_NUMBER !<The element number to evaluate the residual for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code 
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: matrix_idx
    TYPE(ELEMENT_MATRIX_TYPE), POINTER :: ELEMENT_MATRIX
    TYPE(ELEMENT_VECTOR_TYPE), POINTER :: ELEMENT_VECTOR
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_DYNAMIC_TYPE), POINTER :: DYNAMIC_MATRICES
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: LINEAR_MATRICES
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    TYPE(EQUATIONS_MATRICES_RHS_TYPE), POINTER :: RHS_VECTOR
    TYPE(EQUATIONS_MATRICES_SOURCE_TYPE), POINTER :: SOURCE_VECTOR
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    ENTERS("EquationsSet_FiniteElementResidualEvaluate",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(.NOT.ALLOCATED(EQUATIONS_SET%SPECIFICATION)) THEN
        CALL FlagError("Equations set specification is not allocated.",err,error,*999)
      ELSE IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<1) THEN
        CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
      END IF
      SELECT CASE(EQUATIONS_SET%SPECIFICATION(1))
      CASE(EQUATIONS_SET_ELASTICITY_CLASS)
        CALL ELASTICITY_FINITE_ELEMENT_RESIDUAL_EVALUATE(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
        CALL FluidMechanics_FiniteElementResidualEvaluate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
        CALL ClassicalField_FiniteElementResidualEvaluate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_MODAL_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
        CALL MultiPhysics_FiniteElementResidualEvaluate(EQUATIONS_SET,ELEMENT_NUMBER,ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The first equations set specification of "// &
          & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SPECIFICATION(1),"*",ERR,ERROR))//" is not valid."
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN
        EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
        IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
          NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
          IF(ASSOCIATED(NONLINEAR_MATRICES)) THEN
            NONLINEAR_MATRICES%ELEMENT_RESIDUAL_CALCULATED=ELEMENT_NUMBER
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_ELEMENT_MATRIX_OUTPUT) THEN
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Finite element residual matrices and vectors:",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Element number = ",ELEMENT_NUMBER,ERR,ERROR,*999)
              LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
              IF(ASSOCIATED(LINEAR_MATRICES)) THEN
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Linear matrices:",ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Number of element matrices = ",LINEAR_MATRICES% &
                  & NUMBER_OF_LINEAR_MATRICES,ERR,ERROR,*999)
                DO matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Element matrix : ",matrix_idx,ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update matrix = ",LINEAR_MATRICES%MATRICES(matrix_idx)%PTR% &
                    & UPDATE_MATRIX,ERR,ERROR,*999)
                  IF(LINEAR_MATRICES%MATRICES(matrix_idx)%PTR%UPDATE_MATRIX) THEN
                    ELEMENT_MATRIX=>LINEAR_MATRICES%MATRICES(matrix_idx)%PTR%ELEMENT_MATRIX
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_MATRIX%NUMBER_OF_ROWS,ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of columns = ",ELEMENT_MATRIX%NUMBER_OF_COLUMNS, &
                      & ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_MATRIX%MAX_NUMBER_OF_ROWS, &
                      & ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of columns = ",ELEMENT_MATRIX% &
                      & MAX_NUMBER_OF_COLUMNS,ERR,ERROR,*999)
                    CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,8,8,ELEMENT_MATRIX%ROW_DOFS, &
                      & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                    CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX% &
                      & COLUMN_DOFS,'("  Column dofs  :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                    CALL WRITE_STRING_MATRIX(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,1,1,ELEMENT_MATRIX% &
                      & NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX%MATRIX(1:ELEMENT_MATRIX%NUMBER_OF_ROWS,1:ELEMENT_MATRIX% &
                      & NUMBER_OF_COLUMNS),WRITE_STRING_MATRIX_NAME_AND_INDICES,'("  Matrix','(",I2,",:)',' :",8(X,E13.6))', &
                      & '(16X,8(X,E13.6))',ERR,ERROR,*999)
                  ENDIF
                ENDDO !matrix_idx
              ENDIF
              DYNAMIC_MATRICES=>EQUATIONS_MATRICES%DYNAMIC_MATRICES
              IF(ASSOCIATED(DYNAMIC_MATRICES)) THEN
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Dynamnic matrices:",ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Number of element matrices = ",DYNAMIC_MATRICES% &
                  & NUMBER_OF_DYNAMIC_MATRICES,ERR,ERROR,*999)
                DO matrix_idx=1,DYNAMIC_MATRICES%NUMBER_OF_DYNAMIC_MATRICES
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Element matrix : ",matrix_idx,ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update matrix = ",DYNAMIC_MATRICES%MATRICES(matrix_idx)%PTR% &
                    & UPDATE_MATRIX,ERR,ERROR,*999)
                  IF(DYNAMIC_MATRICES%MATRICES(matrix_idx)%PTR%UPDATE_MATRIX) THEN
                    ELEMENT_MATRIX=>DYNAMIC_MATRICES%MATRICES(matrix_idx)%PTR%ELEMENT_MATRIX
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_MATRIX%NUMBER_OF_ROWS,ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of columns = ",ELEMENT_MATRIX%NUMBER_OF_COLUMNS, &
                      & ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_MATRIX%MAX_NUMBER_OF_ROWS, &
                      & ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of columns = ",ELEMENT_MATRIX% &
                      & MAX_NUMBER_OF_COLUMNS,ERR,ERROR,*999)
                    CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,8,8,ELEMENT_MATRIX%ROW_DOFS, &
                      & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                    CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX% &
                      & COLUMN_DOFS,'("  Column dofs  :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                    CALL WRITE_STRING_MATRIX(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_MATRIX%NUMBER_OF_ROWS,1,1,ELEMENT_MATRIX% &
                      & NUMBER_OF_COLUMNS,8,8,ELEMENT_MATRIX%MATRIX(1:ELEMENT_MATRIX%NUMBER_OF_ROWS,1:ELEMENT_MATRIX% &
                      & NUMBER_OF_COLUMNS),WRITE_STRING_MATRIX_NAME_AND_INDICES,'("  Matrix','(",I2,",:)',' :",8(X,E13.6))', &
                      & '(16X,8(X,E13.6))',ERR,ERROR,*999)
                  ENDIF
                ENDDO !matrix_idx
              ENDIF
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Element residual vector:",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update vector = ",NONLINEAR_MATRICES%UPDATE_RESIDUAL,ERR,ERROR,*999)
              IF(NONLINEAR_MATRICES%UPDATE_RESIDUAL) THEN
                ELEMENT_VECTOR=>NONLINEAR_MATRICES%ELEMENT_RESIDUAL
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_VECTOR%NUMBER_OF_ROWS,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_VECTOR%MAX_NUMBER_OF_ROWS, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%ROW_DOFS, &
                  & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%VECTOR, &
                  & '("  Vector(:):",8(X,E13.6))','(16X,8(X,E13.6))',ERR,ERROR,*999)
              ENDIF
              RHS_VECTOR=>EQUATIONS_MATRICES%RHS_VECTOR
              IF(ASSOCIATED(RHS_VECTOR)) THEN
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Element RHS vector :",ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update vector = ",RHS_VECTOR%UPDATE_VECTOR,ERR,ERROR,*999)
                IF(RHS_VECTOR%UPDATE_VECTOR) THEN
                  ELEMENT_VECTOR=>RHS_VECTOR%ELEMENT_VECTOR
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_VECTOR%NUMBER_OF_ROWS,ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_VECTOR%MAX_NUMBER_OF_ROWS, &
                    & ERR,ERROR,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%ROW_DOFS, &
                    & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%VECTOR, &
                    & '("  Vector(:)    :",8(X,E13.6))','(16X,8(X,E13.6))',ERR,ERROR,*999)
                ENDIF
              ENDIF
              SOURCE_VECTOR=>EQUATIONS_MATRICES%SOURCE_VECTOR
              IF(ASSOCIATED(SOURCE_VECTOR)) THEN
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Element source vector :",ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update vector = ",SOURCE_VECTOR%UPDATE_VECTOR,ERR,ERROR,*999)
                IF(SOURCE_VECTOR%UPDATE_VECTOR) THEN
                  ELEMENT_VECTOR=>SOURCE_VECTOR%ELEMENT_VECTOR
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",ELEMENT_VECTOR%NUMBER_OF_ROWS,ERR,ERROR,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",ELEMENT_VECTOR%MAX_NUMBER_OF_ROWS, &
                    & ERR,ERROR,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%ROW_DOFS, &
                    & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',ERR,ERROR,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,ELEMENT_VECTOR%NUMBER_OF_ROWS,8,8,ELEMENT_VECTOR%VECTOR, &
                    & '("  Vector(:)    :",8(X,E13.6))','(16X,8(X,E13.6))',ERR,ERROR,*999)
                ENDIF
              ENDIF
            ENDIF
          ELSE
            CALL FlagError("Equation nonlinear matrices not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equation matrices is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF    
       
    EXITS("EquationsSet_FiniteElementResidualEvaluate")
    RETURN
999 ERRORSEXITS("EquationsSet_FiniteElementResidualEvaluate",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EquationsSet_FiniteElementResidualEvaluate

  !
  !================================================================================================================================
  !

  !>Finish the creation of independent variables for an equations set. \see OPENCMISS::CMISSEquationsSetIndependentCreateFinish
  SUBROUTINE EQUATIONS_SET_INDEPENDENT_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to finish the creation of the independent field for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: INDEPENDENT_FIELD

    ENTERS("EQUATIONS_SET_INDEPENDENT_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%INDEPENDENT)) THEN
        IF(EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FINISHED) THEN
          CALL FlagError("Equations set independent field has already been finished.",ERR,ERROR,*999)
        ELSE
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_INDEPENDENT_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
          INDEPENDENT_FIELD=>EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FIELD
          IF(ASSOCIATED(INDEPENDENT_FIELD)) THEN
            EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=INDEPENDENT_FIELD%USER_NUMBER
            EQUATIONS_SET_SETUP_INFO%FIELD=>INDEPENDENT_FIELD
            !Finish equations set specific startup
            CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          ELSE
            CALL FlagError("Equations set independent independent field is not associated.",ERR,ERROR,*999)
          ENDIF
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finish independent creation
          EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FINISHED=.TRUE.
        ENDIF
      ELSE
        CALL FlagError("The equations set independent is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_INDEPENDENT_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_INDEPENDENT_CREATE_FINISH",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_INDEPENDENT_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Start the creation of independent variables for an equations set. \see OPENCMISS::CMISSEquationsSetIndependentCreateStart
  SUBROUTINE EQUATIONS_SET_INDEPENDENT_CREATE_START(EQUATIONS_SET,INDEPENDENT_FIELD_USER_NUMBER,INDEPENDENT_FIELD,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to start the creation of the materials field for
    INTEGER(INTG), INTENT(IN) :: INDEPENDENT_FIELD_USER_NUMBER !<The user specified independent field number
    TYPE(FIELD_TYPE), POINTER :: INDEPENDENT_FIELD !<If associated on entry, a pointer to the user created independent field which has the same user number as the specified independent field user number. If not associated on entry, on exit, a pointer to the created independent field for the equations set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: FIELD,GEOMETRIC_FIELD
    TYPE(REGION_TYPE), POINTER :: REGION,INDEPENDENT_FIELD_REGION
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    ENTERS("EQUATIONS_SET_INDEPENDENT_CREATE_START",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%INDEPENDENT)) THEN
        CALL FlagError("The equations set independent is already associated",ERR,ERROR,*998)
      ELSE
        REGION=>EQUATIONS_SET%REGION
        IF(ASSOCIATED(REGION)) THEN
          IF(ASSOCIATED(INDEPENDENT_FIELD)) THEN
            !Check the independent field has been finished
            IF(INDEPENDENT_FIELD%FIELD_FINISHED) THEN
              !Check the user numbers match
              IF(INDEPENDENT_FIELD_USER_NUMBER/=INDEPENDENT_FIELD%USER_NUMBER) THEN
                LOCAL_ERROR="The specified independent field user number of "// &
                  & TRIM(NUMBER_TO_VSTRING(INDEPENDENT_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                  & " does not match the user number of the specified independent field of "// &
                  & TRIM(NUMBER_TO_VSTRING(INDEPENDENT_FIELD%USER_NUMBER,"*",ERR,ERROR))//"."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
              INDEPENDENT_FIELD_REGION=>INDEPENDENT_FIELD%REGION
              IF(ASSOCIATED(INDEPENDENT_FIELD_REGION)) THEN                
                !Check the field is defined on the same region as the equations set
                IF(INDEPENDENT_FIELD_REGION%USER_NUMBER/=REGION%USER_NUMBER) THEN
                  LOCAL_ERROR="Invalid region setup. The specified independent field has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(INDEPENDENT_FIELD_REGION%USER_NUMBER,"*",ERR,ERROR))// &
                    & " and the specified equations set has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
                !Check the specified independent field has the same decomposition as the geometric field
                GEOMETRIC_FIELD=>EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD
                IF(ASSOCIATED(GEOMETRIC_FIELD)) THEN
                  IF(.NOT.ASSOCIATED(GEOMETRIC_FIELD%DECOMPOSITION,INDEPENDENT_FIELD%DECOMPOSITION)) THEN
                    CALL FlagError("The specified independent field does not have the same decomposition as the geometric "// &
                      & "field for the specified equations set.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("The geometric field is not associated for the specified equations set.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("The specified independent field region is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("The specified independent field has not been finished.",ERR,ERROR,*999)
            ENDIF
          ELSE
            !Check the user number has not already been used for a field in this region.
            NULLIFY(FIELD)
            CALL FIELD_USER_NUMBER_FIND(INDEPENDENT_FIELD_USER_NUMBER,REGION,FIELD,ERR,ERROR,*999)
            IF(ASSOCIATED(FIELD)) THEN
              LOCAL_ERROR="The specified independent field user number of "// &
                & TRIM(NUMBER_TO_VSTRING(INDEPENDENT_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                & "has already been used to create a field on region number "// &
                & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ENDIF
          !Initialise the equations set independent
          CALL EQUATIONS_SET_INDEPENDENT_INITIALISE(EQUATIONS_SET,ERR,ERROR,*999)
          IF(.NOT.ASSOCIATED(INDEPENDENT_FIELD)) EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FIELD_AUTO_CREATED=.TRUE.
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_INDEPENDENT_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
          EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=INDEPENDENT_FIELD_USER_NUMBER
          EQUATIONS_SET_SETUP_INFO%FIELD=>INDEPENDENT_FIELD
          !Start equations set specific startup
          CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Set pointers
          IF(EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FIELD_AUTO_CREATED) THEN            
            INDEPENDENT_FIELD=>EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FIELD
          ELSE
            EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FIELD=>INDEPENDENT_FIELD
          ENDIF
        ELSE
          CALL FlagError("Equation set region is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_INDEPENDENT_CREATE_START")
    RETURN
999 CALL EQUATIONS_SET_INDEPENDENT_FINALISE(EQUATIONS_SET%INDEPENDENT,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_INDEPENDENT_CREATE_START",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_INDEPENDENT_CREATE_START

  !
  !================================================================================================================================
  !

  !>Destroy the independent field for an equations set. \see OPENCMISS::CMISSEquationsSetIndependentDestroy
  SUBROUTINE EQUATIONS_SET_INDEPENDENT_DESTROY(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to destroy the independent field for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_INDEPENDENT_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%INDEPENDENT)) THEN
        CALL EQUATIONS_SET_INDEPENDENT_FINALISE(EQUATIONS_SET%INDEPENDENT,ERR,ERROR,*999)
      ELSE
        CALL FlagError("Equations set indpendent is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_INDEPENDENT_DESTROY")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_INDEPENDENT_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_INDEPENDENT_DESTROY

  !
  !================================================================================================================================
  !

  !>Finalise the independent field for an equations set.
  SUBROUTINE EQUATIONS_SET_INDEPENDENT_FINALISE(EQUATIONS_SET_INDEPENDENT,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_INDEPENDENT_TYPE), POINTER :: EQUATIONS_SET_INDEPENDENT !<A pointer to the equations set independent to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_INDEPENDENT_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET_INDEPENDENT)) THEN
      DEALLOCATE(EQUATIONS_SET_INDEPENDENT)
    ENDIF
       
    EXITS("EQUATIONS_SET_INDEPENDENT_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_INDEPENDENT_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_INDEPENDENT_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the independent field for an equations set.
  SUBROUTINE EQUATIONS_SET_INDEPENDENT_INITIALISE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the independent for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    ENTERS("EQUATIONS_SET_INDEPENDENT_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%INDEPENDENT)) THEN
        CALL FlagError("Independent field is already associated for these equations sets.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(EQUATIONS_SET%INDEPENDENT,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate equations set independent field.",ERR,ERROR,*999)
        EQUATIONS_SET%INDEPENDENT%EQUATIONS_SET=>EQUATIONS_SET
        EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FINISHED=.FALSE.
        EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FIELD_AUTO_CREATED=.FALSE.
        NULLIFY(EQUATIONS_SET%INDEPENDENT%INDEPENDENT_FIELD)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_INDEPENDENT_INITIALISE")
    RETURN
999 CALL EQUATIONS_SET_INDEPENDENT_FINALISE(EQUATIONS_SET%INDEPENDENT,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_INDEPENDENT_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_INDEPENDENT_INITIALISE

  !
  !================================================================================================================================
  !

  !>Initialises an equations set.
  SUBROUTINE EQUATIONS_SET_INITIALISE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<The pointer to the equations set to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
 
    ENTERS("EQUATIONS_SET_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      CALL FlagError("Equations set is already associated.",ERR,ERROR,*998)
    ELSE
      ALLOCATE(EQUATIONS_SET,STAT=ERR)
      IF(ERR/=0) CALL FlagError("Could not allocate equations set.",ERR,ERROR,*999)
      EQUATIONS_SET%USER_NUMBER=0
      EQUATIONS_SET%GLOBAL_NUMBER=0
      EQUATIONS_SET%EQUATIONS_SET_FINISHED=.FALSE.
      NULLIFY(EQUATIONS_SET%EQUATIONS_SETS)
      NULLIFY(EQUATIONS_SET%REGION)
      EQUATIONS_SET%SOLUTION_METHOD=0
      CALL EQUATIONS_SET_GEOMETRY_INITIALISE(EQUATIONS_SET,ERR,ERROR,*999)
      CALL EQUATIONS_SET_DEPENDENT_INITIALISE(EQUATIONS_SET,ERR,ERROR,*999)
      CALL EquationsSet_EquationsSetFieldInitialise(EQUATIONS_SET,ERR,ERROR,*999)
      NULLIFY(EQUATIONS_SET%INDEPENDENT)
      NULLIFY(EQUATIONS_SET%MATERIALS)
      NULLIFY(EQUATIONS_SET%SOURCE)
      NULLIFY(EQUATIONS_SET%ANALYTIC)
      NULLIFY(EQUATIONS_SET%derived)
      NULLIFY(EQUATIONS_SET%EQUATIONS)
      NULLIFY(EQUATIONS_SET%BOUNDARY_CONDITIONS)
    ENDIF
       
    EXITS("EQUATIONS_SET_INITIALISE")
    RETURN
999 CALL EQUATIONS_SET_FINALISE(EQUATIONS_SET,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finalise the geometry for an equations set
  SUBROUTINE EQUATIONS_SET_GEOMETRY_FINALISE(EQUATIONS_SET_GEOMETRY,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_GEOMETRY_TYPE) :: EQUATIONS_SET_GEOMETRY !<A pointer to the equations set geometry to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_GEOMETRY_FINALISE",ERR,ERROR,*999)
    
    NULLIFY(EQUATIONS_SET_GEOMETRY%GEOMETRIC_FIELD)
    NULLIFY(EQUATIONS_SET_GEOMETRY%FIBRE_FIELD)
       
    EXITS("EQUATIONS_SET_GEOMETRY_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_GEOMETRY_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_GEOMETRY_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the geometry for an equation set
  SUBROUTINE EQUATIONS_SET_GEOMETRY_INITIALISE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the geometry for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    ENTERS("EQUATIONS_SET_GEOMETRY_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS_SET%GEOMETRY%EQUATIONS_SET=>EQUATIONS_SET
      NULLIFY(EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD)
      NULLIFY(EQUATIONS_SET%GEOMETRY%FIBRE_FIELD)
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_GEOMETRY_INITIALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_GEOMETRY_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_GEOMETRY_INITIALISE
  
  !
  !================================================================================================================================
  !

  !>Finish the creation of materials for an equations set. \see OPENCMISS::CMISSEquationsSetMaterialsCreateFinish
  SUBROUTINE EQUATIONS_SET_MATERIALS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to finish the creation of the materials field for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: MATERIALS_FIELD

    ENTERS("EQUATIONS_SET_MATERIALS_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%MATERIALS)) THEN
        IF(EQUATIONS_SET%MATERIALS%MATERIALS_FINISHED) THEN
          CALL FlagError("Equations set materials has already been finished.",ERR,ERROR,*999)
        ELSE
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_MATERIALS_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
          MATERIALS_FIELD=>EQUATIONS_SET%MATERIALS%MATERIALS_FIELD
          IF(ASSOCIATED(MATERIALS_FIELD)) THEN
            EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=MATERIALS_FIELD%USER_NUMBER
            EQUATIONS_SET_SETUP_INFO%FIELD=>MATERIALS_FIELD
            !Finish equations set specific startup
            CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          ELSE
            CALL FlagError("Equations set materials materials field is not associated.",ERR,ERROR,*999)
          ENDIF
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finish materials creation
          EQUATIONS_SET%MATERIALS%MATERIALS_FINISHED=.TRUE.
        ENDIF
      ELSE
        CALL FlagError("The equations set materials is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_MATERIALS_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_MATERIALS_CREATE_FINISH",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_MATERIALS_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Start the creation of materials for a problem. \see OPENCMISS::CMISSEquationsSetMaterialsCreateStart
  SUBROUTINE EQUATIONS_SET_MATERIALS_CREATE_START(EQUATIONS_SET,MATERIALS_FIELD_USER_NUMBER,MATERIALS_FIELD,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to start the creation of the materials field for
    INTEGER(INTG), INTENT(IN) :: MATERIALS_FIELD_USER_NUMBER !<The user specified materials field number
    TYPE(FIELD_TYPE), POINTER :: MATERIALS_FIELD !<If associated on entry, a pointer to the user created materials field which has the same user number as the specified materials field user number. If not associated on entry, on exit, a pointer to the created materials field for the equations set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: FIELD,GEOMETRIC_FIELD
    TYPE(REGION_TYPE), POINTER :: REGION,MATERIALS_FIELD_REGION
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    ENTERS("EQUATIONS_SET_MATERIALS_CREATE_START",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%MATERIALS)) THEN
        CALL FlagError("The equations set materials is already associated",ERR,ERROR,*998)
      ELSE
        REGION=>EQUATIONS_SET%REGION
        IF(ASSOCIATED(REGION)) THEN
          IF(ASSOCIATED(MATERIALS_FIELD)) THEN
            !Check the materials field has been finished
            IF(MATERIALS_FIELD%FIELD_FINISHED) THEN
              !Check the user numbers match
              IF(MATERIALS_FIELD_USER_NUMBER/=MATERIALS_FIELD%USER_NUMBER) THEN
                LOCAL_ERROR="The specified materials field user number of "// &
                  & TRIM(NUMBER_TO_VSTRING(MATERIALS_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                  & " does not match the user number of the specified materials field of "// &
                  & TRIM(NUMBER_TO_VSTRING(MATERIALS_FIELD%USER_NUMBER,"*",ERR,ERROR))//"."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
              MATERIALS_FIELD_REGION=>MATERIALS_FIELD%REGION
              IF(ASSOCIATED(MATERIALS_FIELD_REGION)) THEN                
                !Check the field is defined on the same region as the equations set
                IF(MATERIALS_FIELD_REGION%USER_NUMBER/=REGION%USER_NUMBER) THEN
                  LOCAL_ERROR="Invalid region setup. The specified materials field has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(MATERIALS_FIELD_REGION%USER_NUMBER,"*",ERR,ERROR))// &
                    & " and the specified equations set has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
                !Check the specified materials field has the same decomposition as the geometric field
                GEOMETRIC_FIELD=>EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD
                IF(ASSOCIATED(GEOMETRIC_FIELD)) THEN
                  IF(.NOT.ASSOCIATED(GEOMETRIC_FIELD%DECOMPOSITION,MATERIALS_FIELD%DECOMPOSITION)) THEN
                    CALL FlagError("The specified materials field does not have the same decomposition as the geometric "// &
                      & "field for the specified equations set.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("The geometric field is not associated for the specified equations set.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("The specified materials field region is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("The specified materials field has not been finished.",ERR,ERROR,*999)
            ENDIF
          ELSE
            !Check the user number has not already been used for a field in this region.
            NULLIFY(FIELD)
            CALL FIELD_USER_NUMBER_FIND(MATERIALS_FIELD_USER_NUMBER,REGION,FIELD,ERR,ERROR,*999)
            IF(ASSOCIATED(FIELD)) THEN
              LOCAL_ERROR="The specified materials field user number of "// &
                & TRIM(NUMBER_TO_VSTRING(MATERIALS_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                & "has already been used to create a field on region number "// &
                & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ENDIF
          !Initialise the equations set materials
          CALL EQUATIONS_SET_MATERIALS_INITIALISE(EQUATIONS_SET,ERR,ERROR,*999)
          IF(.NOT.ASSOCIATED(MATERIALS_FIELD)) EQUATIONS_SET%MATERIALS%MATERIALS_FIELD_AUTO_CREATED=.TRUE.
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_MATERIALS_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
          EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=MATERIALS_FIELD_USER_NUMBER
          EQUATIONS_SET_SETUP_INFO%FIELD=>MATERIALS_FIELD
          !Start equations set specific startup
          CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Set pointers
          IF(EQUATIONS_SET%MATERIALS%MATERIALS_FIELD_AUTO_CREATED) THEN            
            MATERIALS_FIELD=>EQUATIONS_SET%MATERIALS%MATERIALS_FIELD
          ELSE
            EQUATIONS_SET%MATERIALS%MATERIALS_FIELD=>MATERIALS_FIELD
          ENDIF
        ELSE
          CALL FlagError("Equation set region is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_MATERIALS_CREATE_START")
    RETURN
999 CALL EQUATIONS_SET_MATERIALS_FINALISE(EQUATIONS_SET%MATERIALS,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_MATERIALS_CREATE_START",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_MATERIALS_CREATE_START

  !
  !================================================================================================================================
  !

  !>Destroy the materials for an equations set. \see OPENCMISS::CMISSEquationsSetMaterialsDestroy
  SUBROUTINE EQUATIONS_SET_MATERIALS_DESTROY(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to destroy the materials for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_MATERIALS_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%MATERIALS)) THEN
        CALL EQUATIONS_SET_MATERIALS_FINALISE(EQUATIONS_SET%MATERIALS,ERR,ERROR,*999)
      ELSE
        CALL FlagError("Equations set materials is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_MATERIALS_DESTROY")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_MATERIALS_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_MATERIALS_DESTROY

  !
  !================================================================================================================================
  !

  !>Finalise the materials for an equations set.
  SUBROUTINE EQUATIONS_SET_MATERIALS_FINALISE(EQUATIONS_SET_MATERIALS,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_MATERIALS_TYPE), POINTER :: EQUATIONS_SET_MATERIALS !<A pointer to the equations set materials to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_MATERIALS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET_MATERIALS)) THEN
      DEALLOCATE(EQUATIONS_SET_MATERIALS)
    ENDIF
       
    EXITS("EQUATIONS_SET_MATERIALS_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_MATERIALS_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_MATERIALS_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the materials for an equations set.
  SUBROUTINE EQUATIONS_SET_MATERIALS_INITIALISE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the materials for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    ENTERS("EQUATIONS_SET_MATERIALS_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%MATERIALS)) THEN
        CALL FlagError("Materials is already associated for these equations sets.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(EQUATIONS_SET%MATERIALS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate equations set materials.",ERR,ERROR,*999)
        EQUATIONS_SET%MATERIALS%EQUATIONS_SET=>EQUATIONS_SET
        EQUATIONS_SET%MATERIALS%MATERIALS_FINISHED=.FALSE.
        EQUATIONS_SET%MATERIALS%MATERIALS_FIELD_AUTO_CREATED=.FALSE.
        NULLIFY(EQUATIONS_SET%MATERIALS%MATERIALS_FIELD)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_MATERIALS_INITIALISE")
    RETURN
999 CALL EQUATIONS_SET_MATERIALS_FINALISE(EQUATIONS_SET%MATERIALS,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_MATERIALS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_MATERIALS_INITIALISE

  !
  !
  !================================================================================================================================
  !

  !>Finish the creation of a dependent variables for an equations set. \see OPENCMISS::CMISSEquationsSetDependentCreateFinish
  SUBROUTINE EQUATIONS_SET_DEPENDENT_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*)
    
    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to finish the creation of
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD

    ENTERS("EQUATIONS_SET_DEPENDENT_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(EQUATIONS_SET%DEPENDENT%DEPENDENT_FINISHED) THEN
        CALL FlagError("Equations set dependent has already been finished",ERR,ERROR,*999)
      ELSE
        !Initialise the setup
        CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_DEPENDENT_TYPE
        EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
        DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
        IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
          EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=DEPENDENT_FIELD%USER_NUMBER
          EQUATIONS_SET_SETUP_INFO%FIELD=>DEPENDENT_FIELD
          !Finish equations set specific setup
          CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        ELSE
          CALL FlagError("Equations set dependent dependent field is not associated.",ERR,ERROR,*999)
        ENDIF
        !Finalise the setup
        CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        !Finish the equations set creation
        EQUATIONS_SET%DEPENDENT%DEPENDENT_FINISHED=.TRUE.
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_DEPENDENT_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_DEPENDENT_CREATE_FINISH",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_DEPENDENT_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Start the creation of dependent variables for an equations set. \see OPENCMISS::CMISSEquationsSetDependentCreateStart
  SUBROUTINE EQUATIONS_SET_DEPENDENT_CREATE_START(EQUATIONS_SET,DEPENDENT_FIELD_USER_NUMBER,DEPENDENT_FIELD,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to start the creation of a dependent field on
    INTEGER(INTG), INTENT(IN) :: DEPENDENT_FIELD_USER_NUMBER !<The user specified dependent field number
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD !<If associated on entry, a pointer to the user created dependent field which has the same user number as the specified dependent field user number. If not associated on entry, on exit, a pointer to the created dependent field for the equations set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: FIELD,GEOMETRIC_FIELD
    TYPE(REGION_TYPE), POINTER :: REGION,DEPENDENT_FIELD_REGION
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR
    
    ENTERS("EQUATIONS_SET_DEPENDENT_CREATE_START",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(EQUATIONS_SET%DEPENDENT%DEPENDENT_FINISHED) THEN
        CALL FlagError("The equations set dependent has been finished.",ERR,ERROR,*999)
      ELSE
        REGION=>EQUATIONS_SET%REGION
        IF(ASSOCIATED(REGION)) THEN
          IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
            !Check the dependent field has been finished
            IF(DEPENDENT_FIELD%FIELD_FINISHED) THEN
              !Check the user numbers match
              IF(DEPENDENT_FIELD_USER_NUMBER/=DEPENDENT_FIELD%USER_NUMBER) THEN
                LOCAL_ERROR="The specified dependent field user number of "// &
                  & TRIM(NUMBER_TO_VSTRING(DEPENDENT_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                  & " does not match the user number of the specified dependent field of "// &
                  & TRIM(NUMBER_TO_VSTRING(DEPENDENT_FIELD%USER_NUMBER,"*",ERR,ERROR))//"."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
              DEPENDENT_FIELD_REGION=>DEPENDENT_FIELD%REGION
              IF(ASSOCIATED(DEPENDENT_FIELD_REGION)) THEN                
                !Check the field is defined on the same region as the equations set
                IF(DEPENDENT_FIELD_REGION%USER_NUMBER/=REGION%USER_NUMBER) THEN
                  LOCAL_ERROR="Invalid region setup. The specified dependent field has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(DEPENDENT_FIELD_REGION%USER_NUMBER,"*",ERR,ERROR))// &
                    & " and the specified equations set has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
                !Check the specified dependent field has the same decomposition as the geometric field
                GEOMETRIC_FIELD=>EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD
                IF(ASSOCIATED(GEOMETRIC_FIELD)) THEN
                  IF(.NOT.ASSOCIATED(GEOMETRIC_FIELD%DECOMPOSITION,DEPENDENT_FIELD%DECOMPOSITION)) THEN
                    CALL FlagError("The specified dependent field does not have the same decomposition as the geometric "// &
                      & "field for the specified equations set.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("The geometric field is not associated for the specified equations set.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("The specified dependent field region is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("The specified dependent field has not been finished.",ERR,ERROR,*999)
            ENDIF
          ELSE
            !Check the user number has not already been used for a field in this region.
            NULLIFY(FIELD)
            CALL FIELD_USER_NUMBER_FIND(DEPENDENT_FIELD_USER_NUMBER,REGION,FIELD,ERR,ERROR,*999)
            IF(ASSOCIATED(FIELD)) THEN
              LOCAL_ERROR="The specified dependent field user number of "// &
                & TRIM(NUMBER_TO_VSTRING(DEPENDENT_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                & " has already been used to create a field on region number "// &
                & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
            EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD_AUTO_CREATED=.TRUE.
          ENDIF
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_DEPENDENT_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
          EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=DEPENDENT_FIELD_USER_NUMBER
          EQUATIONS_SET_SETUP_INFO%FIELD=>DEPENDENT_FIELD
          !Start the equations set specfic solution setup
          CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Set pointers
          IF(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD_AUTO_CREATED) THEN
            DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
          ELSE
            EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD=>DEPENDENT_FIELD
          ENDIF
        ELSE
          CALL FlagError("Equation set region is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Equations_set is not associated.",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_DEPENDENT_CREATE_START")
    RETURN
999 CALL EQUATIONS_SET_DEPENDENT_FINALISE(EQUATIONS_SET%DEPENDENT,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_DEPENDENT_CREATE_START",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_DEPENDENT_CREATE_START

  !
  !================================================================================================================================
  !
  
  !>Destroy the dependent variables for an equations set. \see OPENCMISS::CMISSEquationsSetDependentDestroy
  SUBROUTINE EQUATIONS_SET_DEPENDENT_DESTROY(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<The pointer to the equations set to destroy
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_DEPENDENT_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      CALL EQUATIONS_SET_DEPENDENT_FINALISE(EQUATIONS_SET%DEPENDENT,ERR,ERROR,*999)
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
    
    EXITS("EQUATIONS_SET_DEPENDENT_DESTROY")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_DEPENDENT_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_DEPENDENT_DESTROY
  
  !
  !================================================================================================================================
  !

  !>Finalises the dependent variables for an equation set and deallocates all memory.
  SUBROUTINE EQUATIONS_SET_DEPENDENT_FINALISE(EQUATIONS_SET_DEPENDENT,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_DEPENDENT_TYPE) :: EQUATIONS_SET_DEPENDENT !<The pointer to the equations set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_DEPENDENT_FINALISE",ERR,ERROR,*999)

    NULLIFY(EQUATIONS_SET_DEPENDENT%EQUATIONS_SET)
    EQUATIONS_SET_DEPENDENT%DEPENDENT_FINISHED=.FALSE.
    EQUATIONS_SET_DEPENDENT%DEPENDENT_FIELD_AUTO_CREATED=.FALSE.
    NULLIFY(EQUATIONS_SET_DEPENDENT%DEPENDENT_FIELD)
    
    EXITS("EQUATIONS_SET_DEPENDENT_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_DEPENDENT_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_DEPENDENT_FINALISE
  
  !
  !================================================================================================================================
  !

  !>Initialises the dependent variables for a equations set.
  SUBROUTINE EQUATIONS_SET_DEPENDENT_INITIALISE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the dependent field for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    ENTERS("EQUATIONS_SET_DEPENDENT_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS_SET%DEPENDENT%EQUATIONS_SET=>EQUATIONS_SET
      EQUATIONS_SET%DEPENDENT%DEPENDENT_FINISHED=.FALSE.
      EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD_AUTO_CREATED=.FALSE.
      NULLIFY(EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD)
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_DEPENDENT_INITIALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_DEPENDENT_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_DEPENDENT_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finish the creation of a derived variables field for an equations set. \see OPENCMISS::CMISSEquationsSet_DerivedCreateFinish
  SUBROUTINE EquationsSet_DerivedCreateFinish(equationsSet,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set to finish the derived variable creation for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: equationsSetSetupInfo
    TYPE(FIELD_TYPE), POINTER :: derivedField

    ENTERS("EquationsSet_DerivedCreateFinish",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      IF(ASSOCIATED(equationsSet%derived)) THEN
        IF(equationsSet%derived%derivedFinished) THEN
          CALL FlagError("Equations set derived field information has already been finished",err,error,*999)
        ELSE
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(equationsSetSetupInfo,err,error,*999)
          equationsSetSetupInfo%SETUP_TYPE=EQUATIONS_SET_SETUP_DERIVED_TYPE
          equationsSetSetupInfo%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
          derivedField=>equationsSet%derived%derivedField
          IF(ASSOCIATED(derivedField)) THEN
            equationsSetSetupInfo%FIELD_USER_NUMBER=derivedField%USER_NUMBER
            equationsSetSetupInfo%field=>derivedField
            !Finish equations set specific setup
            CALL EQUATIONS_SET_SETUP(equationsSet,equationsSetSetupInfo,err,error,*999)
          ELSE
            CALL FlagError("Equations set derived field is not associated.",err,error,*999)
          END IF
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(equationsSetSetupInfo,err,error,*999)
          !Finish the equations set derived creation
          equationsSet%derived%derivedFinished=.TRUE.
        END IF
      ELSE
        CALL FlagError("Equations set derived is not associated",err,error,*999)
      END IF
    ELSE
      CALL FlagError("Equations set is not associated",err,error,*999)
    END IF

    EXITS("EquationsSet_DerivedCreateFinish")
    RETURN
999 ERRORSEXITS("EquationsSet_DerivedCreateFinish",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_DerivedCreateFinish

  !
  !================================================================================================================================
  !

  !>Start the creation of derived variables field for an equations set. \see OPENCMISS::CMISSEquationsSet_DerivedCreateStart
  SUBROUTINE EquationsSet_DerivedCreateStart(equationsSet,derivedFieldUserNumber,derivedField,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set to start the creation of a derived field on
    INTEGER(INTG), INTENT(IN) :: derivedFieldUserNumber !<The user specified derived field number
    TYPE(FIELD_TYPE), POINTER :: derivedField !<If associated on entry, a pointer to the user created derived field which has the same user number as the specified derived field user number. If not associated on entry, on exit, a pointer to the created derived field for the equations set.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: dummyErr
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: equationsSetSetupInfo
    TYPE(FIELD_TYPE), POINTER :: field,geometricField
    TYPE(REGION_TYPE), POINTER :: region,derivedFieldRegion
    TYPE(VARYING_STRING) :: dummyError,localError

    ENTERS("EquationsSet_DerivedCreateStart",err,error,*998)

    IF(ASSOCIATED(equationsSet)) THEN
      IF(ASSOCIATED(equationsSet%derived)) THEN
        CALL FlagError("Equations set derived is already associated.",err,error,*998)
      ELSE
        region=>equationsSet%REGION
        IF(ASSOCIATED(region)) THEN
          IF(ASSOCIATED(derivedField)) THEN
            !Check the derived field has been finished
            IF(derivedField%FIELD_FINISHED) THEN
              !Check the user numbers match
              IF(derivedFieldUserNumber/=derivedField%USER_NUMBER) THEN
                localError="The specified derived field user number of "// &
                  & TRIM(NUMBER_TO_VSTRING(derivedFieldUserNumber,"*",err,error))// &
                  & " does not match the user number of the specified derived field of "// &
                  & TRIM(NUMBER_TO_VSTRING(derivedField%USER_NUMBER,"*",err,error))//"."
                CALL FlagError(localError,err,error,*999)
              END IF
              derivedFieldRegion=>derivedField%REGION
              IF(ASSOCIATED(derivedFieldRegion)) THEN
                !Check the field is defined on the same region as the equations set
                IF(derivedFieldRegion%USER_NUMBER/=region%USER_NUMBER) THEN
                  localError="Invalid region setup. The specified derived field has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(derivedFieldRegion%USER_NUMBER,"*",err,error))// &
                    & " and the specified equations set has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(region%USER_NUMBER,"*",err,error))//"."
                  CALL FlagError(localError,err,error,*999)
                END IF
                !Check the specified derived field has the same decomposition as the geometric field
                geometricField=>equationsSet%GEOMETRY%GEOMETRIC_FIELD
                IF(ASSOCIATED(geometricField)) THEN
                  IF(.NOT.ASSOCIATED(geometricField%DECOMPOSITION,derivedField%DECOMPOSITION)) THEN
                    CALL FlagError("The specified derived field does not have the same decomposition as the geometric "// &
                      & "field for the specified equations set.",err,error,*999)
                  END IF
                ELSE
                  CALL FlagError("The geometric field is not associated for the specified equations set.",err,error,*999)
                END IF
              ELSE
                CALL FlagError("The specified derived field region is not associated.",err,error,*999)
              END IF
            ELSE
              CALL FlagError("The specified derived field has not been finished.",err,error,*999)
            END IF
          ELSE
            !Check the user number has not already been used for a field in this region.
            NULLIFY(field)
            CALL FIELD_USER_NUMBER_FIND(derivedFieldUserNumber,region,field,err,error,*999)
            IF(ASSOCIATED(field)) THEN
              localError="The specified derived field user number of "// &
                & TRIM(NUMBER_TO_VSTRING(derivedFieldUserNumber,"*",err,error))// &
                & " has already been used to create a field on region number "// &
                & TRIM(NUMBER_TO_VSTRING(region%USER_NUMBER,"*",err,error))//"."
              CALL FlagError(localError,err,error,*999)
            END IF
            equationsSet%derived%derivedFieldAutoCreated=.TRUE.
          END IF
          CALL EquationsSet_DerivedInitialise(equationsSet,err,error,*999)
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(equationsSetSetupInfo,err,error,*999)
          equationsSetSetupInfo%SETUP_TYPE=EQUATIONS_SET_SETUP_DERIVED_TYPE
          equationsSetSetupInfo%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
          equationsSetSetupInfo%FIELD_USER_NUMBER=derivedFieldUserNumber
          equationsSetSetupInfo%FIELD=>derivedField
          !Start the equations set specfic solution setup
          CALL EQUATIONS_SET_SETUP(equationsSet,equationsSetSetupInfo,err,error,*999)
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(equationsSetSetupInfo,err,error,*999)
          !Set pointers
          IF(.NOT.equationsSet%derived%derivedFieldAutoCreated) THEN
            equationsSet%derived%derivedField=>derivedField
          END IF
        ELSE
          CALL FlagError("Equation set region is not associated.",err,error,*999)
        END IF
      END IF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*998)
    END IF

    EXITS("EquationsSet_DerivedCreateStart")
    RETURN
999 CALL EquationsSet_DerivedFinalise(equationsSet%derived,dummyErr,dummyError,*998)
998 ERRORSEXITS("EquationsSet_DerivedCreateStart",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_DerivedCreateStart

  !
  !================================================================================================================================
  !

  !>Destroy the derived variables for an equations set. \see OPENCMISS::CMISSEquationsSet_DerivedDestroy
  SUBROUTINE EquationsSet_DerivedDestroy(equationsSet,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<The pointer to the equations set to destroy the derived fields for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("EquationsSet_DerivedDestroy",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      CALL EquationsSet_DerivedFinalise(equationsSet%derived,err,error,*999)
    ELSE
      CALL FlagError("Equations set is not associated",err,error,*999)
    END IF

    EXITS("EquationsSet_DerivedDestroy")
    RETURN
999 ERRORSEXITS("EquationsSet_DerivedDestroy",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_DerivedDestroy

  !
  !================================================================================================================================
  !

  !>Finalises the derived variables for an equation set and deallocates all memory.
  SUBROUTINE EquationsSet_DerivedFinalise(equationsSetDerived,err,error,*)

    !Argument variables
    TYPE(EquationsSetDerivedType), POINTER :: equationsSetDerived !<The pointer to the equations set
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string

    ENTERS("EquationsSet_DerivedFinalise",err,error,*999)

    IF(ASSOCIATED(equationsSetDerived)) THEN
      IF(ALLOCATED(equationsSetDerived%variableTypes)) DEALLOCATE(equationsSetDerived%variableTypes)
      DEALLOCATE(equationsSetDerived)
    END IF

    EXITS("EquationsSet_DerivedFinalise")
    RETURN
999 ERRORSEXITS("EquationsSet_DerivedFinalise",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_DerivedFinalise

  !
  !================================================================================================================================
  !

  !>Initialises the derived variables for a equations set.
  SUBROUTINE EquationsSet_DerivedInitialise(equationsSet,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set to initialise the derived field for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string

    ENTERS("EquationsSet_DerivedInitialise",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      IF(ASSOCIATED(equationsSet%derived)) THEN
        CALL FlagError("Derived information is already associated for this equations set.",err,error,*998)
      ELSE
        ALLOCATE(equationsSet%derived,stat=err)
        IF(err/=0) CALL FlagError("Could not allocate equations set derived information.",err,error,*998)
        ALLOCATE(equationsSet%derived%variableTypes(EQUATIONS_SET_NUMBER_OF_DERIVED_TYPES),stat=err)
        IF(err/=0) CALL FlagError("Could not allocate equations set derived variable types.",err,error,*999)
        equationsSet%derived%variableTypes=0
        equationsSet%derived%numberOfVariables=0
        equationsSet%derived%equationsSet=>equationsSet
        equationsSet%derived%derivedFinished=.FALSE.
        equationsSet%derived%derivedFieldAutoCreated=.FALSE.
        NULLIFY(equationsSet%derived%derivedField)
      END IF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    END IF

    EXITS("EquationsSet_DerivedInitialise")
    RETURN
999 CALL EquationsSet_DerivedFinalise(equationsSet%derived,err,error,*999)
998 ERRORSEXITS("EquationsSet_DerivedInitialise",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_DerivedInitialise

  !
  !================================================================================================================================
  !

  !>Finalises the dependent variables for an equation set and deallocates all memory.
  SUBROUTINE EQUATIONS_SET_EQUATIONS_SET_FIELD_FINALISE(EQUATIONS_SET_FIELD,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_EQUATIONS_SET_FIELD_TYPE) :: EQUATIONS_SET_FIELD !<The pointer to the equations set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_EQUATIONS_SET_FIELD_FINALISE",ERR,ERROR,*999)

    NULLIFY(EQUATIONS_SET_FIELD%EQUATIONS_SET)
    EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_FINISHED=.FALSE.
    EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_AUTO_CREATED=.FALSE.
    NULLIFY(EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_FIELD)
    
    EXITS("EQUATIONS_SET_EQUATIONS_SET_FIELD_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_EQUATIONS_SET_FIELD_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_EQUATIONS_SET_FIELD_FINALISE
  
  !
  !================================================================================================================================
  !
  !>Initialises the equations set field for a equations set.
  SUBROUTINE EquationsSet_EquationsSetFieldInitialise(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the dependent field for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    ENTERS("EquationsSet_EquationsSetFieldInitialise",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS_SET%EQUATIONS_SET_FIELD%EQUATIONS_SET=>EQUATIONS_SET
      EQUATIONS_SET%EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_FINISHED=.FALSE.
      EQUATIONS_SET%EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_AUTO_CREATED=.TRUE.
      NULLIFY(EQUATIONS_SET%EQUATIONS_SET_FIELD%EQUATIONS_SET_FIELD_FIELD)
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EquationsSet_EquationsSetFieldInitialise")
    RETURN
999 ERRORSEXITS("EquationsSet_EquationsSetFieldInitialise",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EquationsSet_EquationsSetFieldInitialise

  !
  !================================================================================================================================
  !



  !>Sets up the specifices for an equation set.
  SUBROUTINE EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to perform the setup on
    TYPE(EQUATIONS_SET_SETUP_TYPE), INTENT(INOUT) :: EQUATIONS_SET_SETUP_INFO !<The equations set setup information
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("EQUATIONS_SET_SETUP",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(.NOT.ALLOCATED(EQUATIONS_SET%SPECIFICATION)) THEN
        CALL FlagError("Equations set specification is not allocated.",err,error,*999)
      ELSE IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<1) THEN
        CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
      END IF
      SELECT CASE(EQUATIONS_SET%SPECIFICATION(1))
      CASE(EQUATIONS_SET_ELASTICITY_CLASS)
        CALL ELASTICITY_EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
        CALL FLUID_MECHANICS_EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
        CALL CLASSICAL_FIELD_EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
        IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<2) THEN
          CALL FlagError("Equations set specification must have at least two entries for a bioelectrics equation class.", &
            & err,error,*999)
        END IF
        IF(EQUATIONS_SET%SPECIFICATION(2) == EQUATIONS_SET_MONODOMAIN_STRANG_SPLITTING_EQUATION_TYPE) THEN
          CALL MONODOMAIN_EQUATION_EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        ELSE
          CALL BIOELECTRIC_EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        END IF
      CASE(EQUATIONS_SET_FITTING_CLASS)
        CALL FITTING_EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
      CASE(EQUATIONS_SET_MODAL_CLASS)
        CALL FlagError("Not implemented.",ERR,ERROR,*999)
      CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
        CALL MULTI_PHYSICS_EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The first equations set specification of "// &
          & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SPECIFICATION(1),"*",ERR,ERROR))//" is not valid."
        CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_SETUP")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_SETUP",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_SETUP

  !
  !================================================================================================================================
  !

 !>Finish the creation of equations for the equations set. \see OPENCMISS::CMISSEquationsSetEquationsCreateFinish
  SUBROUTINE EQUATIONS_SET_EQUATIONS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to finish the creation of the equations for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    
    ENTERS("EQUATIONS_SET_EQUATIONS_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      !Initialise the setup
      CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
      EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_EQUATIONS_TYPE
      EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
      !Finish the equations specific solution setup.
      CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
      !Finalise the setup
      CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_EQUATIONS_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_EQUATIONS_CREATE_FINISH",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_EQUATIONS_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Start the creation of equations for the equation set. \see CMISSEquationsSetEquationsCreateStart
  !>Default values set for the EQUATIONS's attributes are:
  !>- OUTPUT_TYPE: 0 (EQUATIONS_SET_NO_OUTPUT)
  !>- SPARSITY_TYPE: 1 (EQUATIONS_SET_SPARSE_MATRICES)
  !>- NONLINEAR_JACOBIAN_TYPE: 0
  !>- INTERPOLATION: null
  !>- LINEAR_DATA: null 
  !>- NONLINEAR_DATA: null
  !>- TIME_DATA: null
  !>- EQUATIONS_MAPPING:  
  !>- EQUATIONS_MATRICES:  
  SUBROUTINE EQUATIONS_SET_EQUATIONS_CREATE_START(EQUATIONS_SET,EQUATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to create equations for
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS !<On exit, a pointer to the created equations. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO

    ENTERS("EQUATIONS_SET_EQUATIONS_CREATE_START",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS)) THEN
        CALL FlagError("Equations is already associated.",ERR,ERROR,*999)
      ELSE
        !Initialise the setup
        CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_EQUATIONS_TYPE
        EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
        !Start the equations set specific solution setup
        CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        !Finalise the setup
        CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
        !Return the pointer
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_EQUATIONS_CREATE_START")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_EQUATIONS_CREATE_START",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_EQUATIONS_CREATE_START

  !
  !================================================================================================================================
  !

  !>Destroy the equations for an equations set. \see OPENCMISS::CMISSEquationsSetEquationsDestroy
  SUBROUTINE EQUATIONS_SET_EQUATIONS_DESTROY(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to destroy the equations for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_EQUATIONS_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%EQUATIONS)) THEN
        CALL EQUATIONS_FINALISE(EQUATIONS_SET%EQUATIONS,ERR,ERROR,*999)
      ELSE
        CALL FlagError("Equations set equations is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_EQUATIONS_DESTROY")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_EQUATIONS_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_EQUATIONS_DESTROY

  !
  !================================================================================================================================
  !

  !>Evaluates the Jacobian for a nonlinear equations set.
  SUBROUTINE EQUATIONS_SET_JACOBIAN_EVALUATE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to evaluate the Jacobian for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    ENTERS("EQUATIONS_SET_JACOBIAN_EVALUATE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN
        IF(EQUATIONS%EQUATIONS_FINISHED) THEN
          SELECT CASE(EQUATIONS%LINEARITY)
          CASE(EQUATIONS_LINEAR)
            SELECT CASE(EQUATIONS%TIME_DEPENDENCE)
            CASE(EQUATIONS_STATIC)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_ASSEMBLE_STATIC_LINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_QUASISTATIC)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EquationsSet_AssembleQuasistaticLinearFEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_FIRST_ORDER_DYNAMIC,EQUATIONS_SECOND_ORDER_DYNAMIC)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_ASSEMBLE_DYNAMIC_LINEAR_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE DEFAULT
              LOCAL_ERROR="The equations time dependence type of "// &
                & TRIM(NUMBER_TO_VSTRING(EQUATIONS%TIME_DEPENDENCE,"*",ERR,ERROR))//" is invalid."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          CASE(EQUATIONS_NONLINEAR)
            SELECT CASE(EQUATIONS%TIME_DEPENDENCE)
            CASE(EQUATIONS_STATIC)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_JACOBIAN_EVALUATE_STATIC_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_NODAL_SOLUTION_METHOD)
                CALL EquationsSet_JacobianEvaluateStaticNodal(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method  of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_QUASISTATIC)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_JACOBIAN_EVALUATE_STATIC_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method  of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_FIRST_ORDER_DYNAMIC,EQUATIONS_SECOND_ORDER_DYNAMIC)
! sebk 15/09/09
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_JACOBIAN_EVALUATE_DYNAMIC_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method  of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_TIME_STEPPING)
              CALL FlagError("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The equations set time dependence type of "// &
                & TRIM(NUMBER_TO_VSTRING(EQUATIONS%TIME_DEPENDENCE,"*",ERR,ERROR))//" is invalid."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          CASE(EQUATIONS_NONLINEAR_BCS)
            CALL FlagError("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The equations linearity of "// &
              & TRIM(NUMBER_TO_VSTRING(EQUATIONS%LINEARITY,"*",ERR,ERROR))//" is invalid."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FlagError("Equations have not been finished.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations set equations is not associated.",ERR,ERROR,*999)
      ENDIF      
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_JACOBIAN_EVALUATE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_JACOBIAN_EVALUATE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_JACOBIAN_EVALUATE

  !
  !================================================================================================================================
  !

  !>Evaluates the Jacobian for an static equations set using the finite element method
  SUBROUTINE EQUATIONS_SET_JACOBIAN_EVALUATE_STATIC_FEM(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to evaluate the Jacobian for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_idx,ne,NUMBER_OF_TIMES
    REAL(SP) :: ELEMENT_USER_ELAPSED,ELEMENT_SYSTEM_ELAPSED,USER_ELAPSED,USER_TIME1(1),USER_TIME2(1),USER_TIME3(1),USER_TIME4(1), &
      & USER_TIME5(1),USER_TIME6(1),SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),SYSTEM_TIME3(1),SYSTEM_TIME4(1), &
      & SYSTEM_TIME5(1),SYSTEM_TIME6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
  
    ENTERS("EQUATIONS_SET_JACOBIAN_EVALUATE_STATIC_FEM",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
        IF(ASSOCIATED(EQUATIONS)) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
            ENDIF
!!Do we need to transfer parameter sets???
            !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(EQUATIONS_MATRICES,EQUATIONS_MATRICES_JACOBIAN_ONLY,0.0_DP,ERR,ERROR,*999)
            !Assemble the elements
            !Allocate the element matrices 
            CALL EQUATIONS_MATRICES_ELEMENT_INITIALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ELEMENTS_MAPPING=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%ELEMENTS
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              ELEMENT_USER_ELAPSED=0.0_SP
              ELEMENT_SYSTEM_ELAPSED=0.0_SP
            ENDIF
            NUMBER_OF_TIMES=0
            !Loop over the internal elements
            DO element_idx=ELEMENTS_MAPPING%INTERNAL_START,ELEMENTS_MAPPING%INTERNAL_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EquationsSet_FiniteElementJacobianEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_JACOBIAN_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx                  
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME3,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME3,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME3(1)-USER_TIME2(1)
              SYSTEM_ELAPSED=SYSTEM_TIME3(1)-SYSTEM_TIME2(1)
              ELEMENT_USER_ELAPSED=USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=SYSTEM_ELAPSED
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME4,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME4,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME4(1)-USER_TIME3(1)
              SYSTEM_ELAPSED=SYSTEM_TIME4(1)-SYSTEM_TIME3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Loop over the boundary and ghost elements
            DO element_idx=ELEMENTS_MAPPING%BOUNDARY_START,ELEMENTS_MAPPING%GHOST_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EquationsSet_FiniteElementJacobianEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_JACOBIAN_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME5,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME5,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME5(1)-USER_TIME4(1)
              SYSTEM_ELAPSED=SYSTEM_TIME5(1)-SYSTEM_TIME4(1)
              ELEMENT_USER_ELAPSED=ELEMENT_USER_ELAPSED+USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=ELEMENT_SYSTEM_ELAPSED+USER_ELAPSED
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              IF(NUMBER_OF_TIMES>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element user time for equations assembly = ", &
                  & ELEMENT_USER_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element system time for equations assembly = ", &
                  & ELEMENT_SYSTEM_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Finalise the element matrices
            CALL EQUATIONS_MATRICES_ELEMENT_FINALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            !Output equations matrices and RHS vector if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_JACOBIAN_OUTPUT(GENERAL_OUTPUT_TYPE,EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME6,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME6,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME6(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME6(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",ERR,ERROR,*999)
      ENDIF            
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_JACOBIAN_EVALUATE_STATIC_FEM")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_JACOBIAN_EVALUATE_STATIC_FEM",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_JACOBIAN_EVALUATE_STATIC_FEM

  !
  !================================================================================================================================
  !

  !>Evaluates the Jacobian for an dynamic equations set using the finite element method
  SUBROUTINE EQUATIONS_SET_JACOBIAN_EVALUATE_DYNAMIC_FEM(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to evaluate the Jacobian for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_idx,ne,NUMBER_OF_TIMES
    REAL(SP) :: ELEMENT_USER_ELAPSED,ELEMENT_SYSTEM_ELAPSED,USER_ELAPSED,USER_TIME1(1),USER_TIME2(1),USER_TIME3(1),USER_TIME4(1), &
      & USER_TIME5(1),USER_TIME6(1),SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),SYSTEM_TIME3(1),SYSTEM_TIME4(1), &
      & SYSTEM_TIME5(1),SYSTEM_TIME6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
  
    ENTERS("EQUATIONS_SET_JACOBIAN_EVALUATE_DYNAMIC_FEM",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
        IF(ASSOCIATED(EQUATIONS)) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
            ENDIF
!!Do we need to transfer parameter sets???
            !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(EQUATIONS_MATRICES,EQUATIONS_MATRICES_JACOBIAN_ONLY,0.0_DP,ERR,ERROR,*999)
            !Assemble the elements
            !Allocate the element matrices 
            CALL EQUATIONS_MATRICES_ELEMENT_INITIALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ELEMENTS_MAPPING=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%ELEMENTS
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              ELEMENT_USER_ELAPSED=0.0_SP
              ELEMENT_SYSTEM_ELAPSED=0.0_SP
            ENDIF
            NUMBER_OF_TIMES=0
            !Loop over the internal elements
            DO element_idx=ELEMENTS_MAPPING%INTERNAL_START,ELEMENTS_MAPPING%INTERNAL_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EquationsSet_FiniteElementJacobianEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_JACOBIAN_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME3,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME3,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME3(1)-USER_TIME2(1)
              SYSTEM_ELAPSED=SYSTEM_TIME3(1)-SYSTEM_TIME2(1)
              ELEMENT_USER_ELAPSED=USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=SYSTEM_ELAPSED
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME4,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME4,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME4(1)-USER_TIME3(1)
              SYSTEM_ELAPSED=SYSTEM_TIME4(1)-SYSTEM_TIME3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Loop over the boundary and ghost elements
            DO element_idx=ELEMENTS_MAPPING%BOUNDARY_START,ELEMENTS_MAPPING%GHOST_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EquationsSet_FiniteElementJacobianEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_JACOBIAN_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME5,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME5,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME5(1)-USER_TIME4(1)
              SYSTEM_ELAPSED=SYSTEM_TIME5(1)-SYSTEM_TIME4(1)
              ELEMENT_USER_ELAPSED=ELEMENT_USER_ELAPSED+USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=ELEMENT_SYSTEM_ELAPSED+USER_ELAPSED
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              IF(NUMBER_OF_TIMES>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element user time for equations assembly = ", &
                  & ELEMENT_USER_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element system time for equations assembly = ", &
                  & ELEMENT_SYSTEM_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Finalise the element matrices
            CALL EQUATIONS_MATRICES_ELEMENT_FINALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
             !Output equations matrices and RHS vector if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_JACOBIAN_OUTPUT(GENERAL_OUTPUT_TYPE,EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME6,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME6,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME6(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME6(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",ERR,ERROR,*999)
      ENDIF            
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_JACOBIAN_EVALUATE_DYNAMIC_FEM")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_JACOBIAN_EVALUATE_DYNAMIC_FEM",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_JACOBIAN_EVALUATE_DYNAMIC_FEM

  !
  !================================================================================================================================
  !

  !>Evaluates the residual for an equations set.
  SUBROUTINE EQUATIONS_SET_RESIDUAL_EVALUATE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to evaluate the residual for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: residual_variable_idx
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_NONLINEAR_TYPE), POINTER :: NONLINEAR_MAPPING
    TYPE(FIELD_PARAMETER_SET_TYPE), POINTER :: RESIDUAL_PARAMETER_SET
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: RESIDUAL_VARIABLE
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    ENTERS("EQUATIONS_SET_RESIDUAL_EVALUATE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      EQUATIONS=>EQUATIONS_SET%EQUATIONS
      IF(ASSOCIATED(EQUATIONS)) THEN
        IF(EQUATIONS%EQUATIONS_FINISHED) THEN
          SELECT CASE(EQUATIONS%LINEARITY)
          CASE(EQUATIONS_LINEAR)
            CALL FlagError("Can not evaluate a residual for linear equations.",ERR,ERROR,*999)
          CASE(EQUATIONS_NONLINEAR)
            SELECT CASE(EQUATIONS%TIME_DEPENDENCE)
            CASE(EQUATIONS_STATIC,EQUATIONS_QUASISTATIC)!Quasistatic handled like static
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_RESIDUAL_EVALUATE_STATIC_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_NODAL_SOLUTION_METHOD)
                CALL EquationsSet_ResidualEvaluateStaticNodal(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method  of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE(EQUATIONS_FIRST_ORDER_DYNAMIC,EQUATIONS_SECOND_ORDER_DYNAMIC)
              SELECT CASE(EQUATIONS_SET%SOLUTION_METHOD)
              CASE(EQUATIONS_SET_FEM_SOLUTION_METHOD)
                CALL EQUATIONS_SET_RESIDUAL_EVALUATE_DYNAMIC_FEM(EQUATIONS_SET,ERR,ERROR,*999)
              CASE(EQUATIONS_SET_BEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FD_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_FV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFEM_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE(EQUATIONS_SET_GFV_SOLUTION_METHOD)
                CALL FlagError("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The equations set solution method  of "// &
                  & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SOLUTION_METHOD,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            CASE DEFAULT
              LOCAL_ERROR="The equations set time dependence type of "// &
                & TRIM(NUMBER_TO_VSTRING(EQUATIONS%TIME_DEPENDENCE,"*",ERR,ERROR))//" is invalid."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          CASE(EQUATIONS_NONLINEAR_BCS)
            CALL FlagError("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The equations linearity of "// &
              & TRIM(NUMBER_TO_VSTRING(EQUATIONS%LINEARITY,"*",ERR,ERROR))//" is invalid."
            CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
          !Update the residual parameter set if it exists
          EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
          IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
            NONLINEAR_MAPPING=>EQUATIONS_MAPPING%NONLINEAR_MAPPING
            IF(ASSOCIATED(NONLINEAR_MAPPING)) THEN
              DO residual_variable_idx=1,NONLINEAR_MAPPING%NUMBER_OF_RESIDUAL_VARIABLES
                RESIDUAL_VARIABLE=>NONLINEAR_MAPPING%RESIDUAL_VARIABLES(residual_variable_idx)%PTR
                IF(ASSOCIATED(RESIDUAL_VARIABLE)) THEN
                  RESIDUAL_PARAMETER_SET=>RESIDUAL_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_RESIDUAL_SET_TYPE)%PTR
                  IF(ASSOCIATED(RESIDUAL_PARAMETER_SET)) THEN
                    !Residual parameter set exists
                    EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                    IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                      NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
                      IF(ASSOCIATED(NONLINEAR_MATRICES)) THEN
                        !Copy the residual vector to the residuals parameter set.
                        CALL DISTRIBUTED_VECTOR_COPY(NONLINEAR_MATRICES%RESIDUAL,RESIDUAL_PARAMETER_SET%PARAMETERS,1.0_DP, &
                          & ERR,ERROR,*999)
                      ELSE
                        CALL FlagError("Equations matrices nonlinear matrices is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      CALL FlagError("Equations equations matrices is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ENDIF
                ELSE
                  LOCAL_ERROR="Nonlinear mapping residual variable for residual variable index "// &
                    & TRIM(NUMBER_TO_VSTRING(residual_variable_idx,"*",ERR,ERROR))//" is not associated."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ENDDO !residual_variable_idx
            ELSE
              CALL FlagError("Equations mapping nonlinear mapping is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations equations mapping is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations have not been finished.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations set equations is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_RESIDUAL_EVALUATE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_RESIDUAL_EVALUATE",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_RESIDUAL_EVALUATE

  !
  !================================================================================================================================
  !

  !>Evaluates the residual for an dynamic equations set using the finite element method
  SUBROUTINE EQUATIONS_SET_RESIDUAL_EVALUATE_DYNAMIC_FEM(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to evaluate the residual for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_idx,ne,NUMBER_OF_TIMES
    REAL(SP) :: ELEMENT_USER_ELAPSED,ELEMENT_SYSTEM_ELAPSED,USER_ELAPSED,USER_TIME1(1),USER_TIME2(1),USER_TIME3(1),USER_TIME4(1), &
      & USER_TIME5(1),USER_TIME6(1),SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),SYSTEM_TIME3(1),SYSTEM_TIME4(1), &
      & SYSTEM_TIME5(1),SYSTEM_TIME6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
 
    ENTERS("EQUATIONS_SET_RESIDUAL_EVALUATE_DYNAMIC_FEM",ERR,ERROR,*999)

    NULLIFY(ELEMENTS_MAPPING)
    NULLIFY(EQUATIONS)
    NULLIFY(EQUATIONS_MATRICES)
    NULLIFY(DEPENDENT_FIELD)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
        IF(ASSOCIATED(EQUATIONS)) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
            ENDIF
            !!Do we need to transfer parameter sets???
            !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(EQUATIONS_MATRICES,EQUATIONS_MATRICES_NONLINEAR_ONLY,0.0_DP,ERR,ERROR,*999)
            !Assemble the elements
            !Allocate the element matrices 
            CALL EQUATIONS_MATRICES_ELEMENT_INITIALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ELEMENTS_MAPPING=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%ELEMENTS
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              ELEMENT_USER_ELAPSED=0.0_SP
              ELEMENT_SYSTEM_ELAPSED=0.0_SP
            ENDIF
            NUMBER_OF_TIMES=0
            !Loop over the internal elements
            DO element_idx=ELEMENTS_MAPPING%INTERNAL_START,ELEMENTS_MAPPING%INTERNAL_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EquationsSet_FiniteElementResidualEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx                  
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME3,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME3,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME3(1)-USER_TIME2(1)
              SYSTEM_ELAPSED=SYSTEM_TIME3(1)-SYSTEM_TIME2(1)
              ELEMENT_USER_ELAPSED=USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=SYSTEM_ELAPSED
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
             ENDIF
             !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME4,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME4,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME4(1)-USER_TIME3(1)
              SYSTEM_ELAPSED=SYSTEM_TIME4(1)-SYSTEM_TIME3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Loop over the boundary and ghost elements
            DO element_idx=ELEMENTS_MAPPING%BOUNDARY_START,ELEMENTS_MAPPING%GHOST_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EquationsSet_FiniteElementResidualEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME5,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME5,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME5(1)-USER_TIME4(1)
              SYSTEM_ELAPSED=SYSTEM_TIME5(1)-SYSTEM_TIME4(1)
              ELEMENT_USER_ELAPSED=ELEMENT_USER_ELAPSED+USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=ELEMENT_SYSTEM_ELAPSED+USER_ELAPSED
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              IF(NUMBER_OF_TIMES>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element user time for equations assembly = ", &
                  & ELEMENT_USER_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element system time for equations assembly = ", &
                  & ELEMENT_SYSTEM_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Finalise the element matrices
            CALL EQUATIONS_MATRICES_ELEMENT_FINALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            !Output equations matrices and RHS vector if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME6,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME6,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME6(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME6(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_RESIDUAL_EVALUATE_DYNAMIC_FEM")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_RESIDUAL_EVALUATE_DYNAMIC_FEM",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_RESIDUAL_EVALUATE_DYNAMIC_FEM

  !
  !================================================================================================================================
  !

  !>Evaluates the residual for an static equations set using the finite element method
  SUBROUTINE EQUATIONS_SET_RESIDUAL_EVALUATE_STATIC_FEM(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to evaluate the residual for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: element_idx,ne,NUMBER_OF_TIMES
    REAL(SP) :: ELEMENT_USER_ELAPSED,ELEMENT_SYSTEM_ELAPSED,USER_ELAPSED,USER_TIME1(1),USER_TIME2(1),USER_TIME3(1),USER_TIME4(1), &
      & USER_TIME5(1),USER_TIME6(1),SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),SYSTEM_TIME3(1),SYSTEM_TIME4(1), &
      & SYSTEM_TIME5(1),SYSTEM_TIME6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ELEMENTS_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
 
    ENTERS("EQUATIONS_SET_RESIDUAL_EVALUATE_STATIC_FEM",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
        EQUATIONS=>EQUATIONS_SET%EQUATIONS
        IF(ASSOCIATED(EQUATIONS)) THEN
          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
            ENDIF
            !!Do we need to transfer parameter sets???
            !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(EQUATIONS_MATRICES,EQUATIONS_MATRICES_NONLINEAR_ONLY,0.0_DP,ERR,ERROR,*999)
            !Assemble the elements
            !Allocate the element matrices 
            CALL EQUATIONS_MATRICES_ELEMENT_INITIALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ELEMENTS_MAPPING=>DEPENDENT_FIELD%DECOMPOSITION%DOMAIN(DEPENDENT_FIELD%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%ELEMENTS
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              ELEMENT_USER_ELAPSED=0.0_SP
              ELEMENT_SYSTEM_ELAPSED=0.0_SP
            ENDIF
            NUMBER_OF_TIMES=0
            !Loop over the internal elements
            DO element_idx=ELEMENTS_MAPPING%INTERNAL_START,ELEMENTS_MAPPING%INTERNAL_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EquationsSet_FiniteElementResidualEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME3,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME3,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME3(1)-USER_TIME2(1)
              SYSTEM_ELAPSED=SYSTEM_TIME3(1)-SYSTEM_TIME2(1)
              ELEMENT_USER_ELAPSED=USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=SYSTEM_ELAPSED
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME4,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME4,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME4(1)-USER_TIME3(1)
              SYSTEM_ELAPSED=SYSTEM_TIME4(1)-SYSTEM_TIME3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
            !Loop over the boundary and ghost elements
            DO element_idx=ELEMENTS_MAPPING%BOUNDARY_START,ELEMENTS_MAPPING%GHOST_FINISH
              ne=ELEMENTS_MAPPING%DOMAIN_LIST(element_idx)
              NUMBER_OF_TIMES=NUMBER_OF_TIMES+1
              CALL EQUATIONS_MATRICES_ELEMENT_CALCULATE(EQUATIONS_MATRICES,ne,ERR,ERROR,*999)
              CALL EquationsSet_FiniteElementResidualEvaluate(EQUATIONS_SET,ne,ERR,ERROR,*999)
              CALL EQUATIONS_MATRICES_ELEMENT_ADD(EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDDO !element_idx
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME5,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME5,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME5(1)-USER_TIME4(1)
              SYSTEM_ELAPSED=SYSTEM_TIME5(1)-SYSTEM_TIME4(1)
              ELEMENT_USER_ELAPSED=ELEMENT_USER_ELAPSED+USER_ELAPSED
              ELEMENT_SYSTEM_ELAPSED=ELEMENT_SYSTEM_ELAPSED+USER_ELAPSED
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
              IF(NUMBER_OF_TIMES>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element user time for equations assembly = ", &
                  & ELEMENT_USER_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average element system time for equations assembly = ", &
                  & ELEMENT_SYSTEM_ELAPSED/NUMBER_OF_TIMES,ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Finalise the element matrices
            CALL EQUATIONS_MATRICES_ELEMENT_FINALISE(EQUATIONS_MATRICES,ERR,ERROR,*999)
            !Output equations matrices and RHS vector if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,EQUATIONS_MATRICES,ERR,ERROR,*999)
            ENDIF
            !Output timing information if required
            IF(EQUATIONS%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,USER_TIME6,ERR,ERROR,*999)
              CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME6,ERR,ERROR,*999)
              USER_ELAPSED=USER_TIME6(1)-USER_TIME1(1)
              SYSTEM_ELAPSED=SYSTEM_TIME6(1)-SYSTEM_TIME1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",USER_ELAPSED, &
                & ERR,ERROR,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",SYSTEM_ELAPSED, &
                & ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_RESIDUAL_EVALUATE_STATIC_FEM")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_RESIDUAL_EVALUATE_STATIC_FEM",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_RESIDUAL_EVALUATE_STATIC_FEM

  !
  !================================================================================================================================
  !

  !>Finalises the equations set setup and deallocates all memory
  SUBROUTINE EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_SETUP_TYPE), INTENT(OUT) :: EQUATIONS_SET_SETUP_INFO !<The equations set setup to be finalised
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_SETUP_FINALISE",ERR,ERROR,*999)

    EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=0
    EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=0
    EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=0
    NULLIFY(EQUATIONS_SET_SETUP_INFO%FIELD)
    EQUATIONS_SET_SETUP_INFO%ANALYTIC_FUNCTION_TYPE=0
    
    EXITS("EQUATIONS_SET_SETUP_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_SETUP_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_SETUP_FINALISE
  
  !
  !================================================================================================================================
  !

  !>Initialise the equations set setup.
  SUBROUTINE EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_SETUP_TYPE), INTENT(OUT) :: EQUATIONS_SET_SETUP_INFO !<The equations set setup to be initialised
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_SETUP_INITIALISE",ERR,ERROR,*999)

    EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=0
    EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=0
    EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=0
    NULLIFY(EQUATIONS_SET_SETUP_INFO%FIELD)
    EQUATIONS_SET_SETUP_INFO%ANALYTIC_FUNCTION_TYPE=0
    
    EXITS("EQUATIONS_SET_SETUP_INITIALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_SETUP_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_SETUP_INITIALISE
  
  !
  !================================================================================================================================
  !

  !>Sets/changes the solution method for an equations set. \see OPENCMISS::CMISSEquationsSetSolutionMethodSet
  SUBROUTINE EQUATIONS_SET_SOLUTION_METHOD_SET(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to set the solution method for
    INTEGER(INTG), INTENT(IN) :: SOLUTION_METHOD !<The equations set solution method to set \see EQUATIONS_SET_CONSTANTS_SolutionMethods,EQUATIONS_SET_CONSTANTS
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("EQUATIONS_SET_SOLUTION_METHOD_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(EQUATIONS_SET%EQUATIONS_SET_FINISHED) THEN
        CALL FlagError("Equations set has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(.NOT.ALLOCATED(EQUATIONS_SET%SPECIFICATION)) THEN
          CALL FlagError("Equations set specification is not allocated.",err,error,*999)
        ELSE IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<1) THEN
          CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
        END IF
        SELECT CASE(EQUATIONS_SET%SPECIFICATION(1))
        CASE(EQUATIONS_SET_ELASTICITY_CLASS)
          CALL Elasticity_EquationsSetSolutionMethodSet(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*999)
        CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
          CALL FluidMechanics_EquationsSetSolutionMethodSet(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*999)
        CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
          CALL ClassicalField_EquationsSetSolutionMethodSet(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*999)
        CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
          IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<2) THEN
            CALL FlagError("Equations set specification must have at least two entries for a bioelectrics equation set.", &
              & err,error,*999)
          END IF
          IF(EQUATIONS_SET%SPECIFICATION(2) == EQUATIONS_SET_MONODOMAIN_STRANG_SPLITTING_EQUATION_TYPE) THEN
            CALL Monodomain_EquationsSetSolutionMethodSet(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*999)
          ELSE
            CALL Bioelectric_EquationsSetSolutionMethodSet(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*999)
          END IF
        CASE(EQUATIONS_SET_MODAL_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
          CALL MultiPhysics_EquationsSetSolnMethodSet(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*999)
        CASE DEFAULT
          LOCAL_ERROR="The first equations set specification of "// &
            & TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET%SPECIFICATION(1),"*",ERR,ERROR))//" is invalid."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
    
    EXITS("EQUATIONS_SET_SOLUTION_METHOD_SET")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_SOLUTION_METHOD_SET",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_SOLUTION_METHOD_SET
  
  !
  !================================================================================================================================
  !

  !>Returns the solution method for an equations set. \see OPENCMISS::CMISSEquationsSetSolutionMethodGet
  SUBROUTINE EQUATIONS_SET_SOLUTION_METHOD_GET(EQUATIONS_SET,SOLUTION_METHOD,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to get the solution method for
    INTEGER(INTG), INTENT(OUT) :: SOLUTION_METHOD !<On return, the equations set solution method \see EQUATIONS_SET_CONSTANTS_SolutionMethods,EQUATIONS_SET_CONSTANTS
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_SOLUTION_METHOD_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(EQUATIONS_SET%EQUATIONS_SET_FINISHED) THEN
        SOLUTION_METHOD=EQUATIONS_SET%SOLUTION_METHOD
      ELSE
        CALL FlagError("Equations set has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
    
    EXITS("EQUATIONS_SET_SOLUTION_METHOD_GET")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_SOLUTION_METHOD_GET",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_SOLUTION_METHOD_GET
  
  !
  !================================================================================================================================
  !

  !>Finish the creation of a source for an equation set. \see OPENCMISS::CMISSEquationsSetSourceCreateFinish
  SUBROUTINE EQUATIONS_SET_SOURCE_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to start the creation of a souce for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: SOURCE_FIELD

    ENTERS("EQUATIONS_SET_SOURCE_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%SOURCE)) THEN
        IF(EQUATIONS_SET%SOURCE%SOURCE_FINISHED) THEN
          CALL FlagError("Equations set source has already been finished.",ERR,ERROR,*999)
        ELSE
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_SOURCE_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_FINISH_ACTION
          SOURCE_FIELD=>EQUATIONS_SET%SOURCE%SOURCE_FIELD
          IF(ASSOCIATED(SOURCE_FIELD)) THEN
            EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=SOURCE_FIELD%USER_NUMBER
            EQUATIONS_SET_SETUP_INFO%FIELD=>SOURCE_FIELD
            !Finish the equation set specific source setup
            CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          ELSE
            CALL FlagError("Equations set source source field is not associated.",ERR,ERROR,*999)
          ENDIF
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finish the source creation
          EQUATIONS_SET%SOURCE%SOURCE_FINISHED=.TRUE.
        ENDIF
      ELSE
        CALL FlagError("The equations set source is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_SOURCE_CREATE_FINISH")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_SOURCE_CREATE_FINISH",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_SOURCE_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Start the creation of a source for an equations set. \see OPENCMISS::CMISSEquationsSetSourceCreateStart
  SUBROUTINE EQUATIONS_SET_SOURCE_CREATE_START(EQUATIONS_SET,SOURCE_FIELD_USER_NUMBER,SOURCE_FIELD,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to start the creation of a source for
    INTEGER(INTG), INTENT(IN) :: SOURCE_FIELD_USER_NUMBER !<The user specified source field number
    TYPE(FIELD_TYPE), POINTER :: SOURCE_FIELD !<If associated on entry, a pointer to the user created source field which has the same user number as the specified source field user number. If not associated on entry, on exit, a pointer to the created source field for the equations set.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(EQUATIONS_SET_SETUP_TYPE) :: EQUATIONS_SET_SETUP_INFO
    TYPE(FIELD_TYPE), POINTER :: FIELD,GEOMETRIC_FIELD
    TYPE(REGION_TYPE), POINTER :: REGION,SOURCE_FIELD_REGION
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    ENTERS("EQUATIONS_SET_SOURCE_CREATE_START",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%SOURCE)) THEN
        CALL FlagError("The equations set source is already associated.",ERR,ERROR,*998)
      ELSE
        REGION=>EQUATIONS_SET%REGION
        IF(ASSOCIATED(REGION)) THEN
          IF(ASSOCIATED(SOURCE_FIELD)) THEN
            !Check the source field has been finished
            IF(SOURCE_FIELD%FIELD_FINISHED) THEN
              !Check the user numbers match
              IF(SOURCE_FIELD_USER_NUMBER/=SOURCE_FIELD%USER_NUMBER) THEN
                LOCAL_ERROR="The specified source field user number of "// &
                  & TRIM(NUMBER_TO_VSTRING(SOURCE_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                  & " does not match the user number of the specified source field of "// &
                  & TRIM(NUMBER_TO_VSTRING(SOURCE_FIELD%USER_NUMBER,"*",ERR,ERROR))//"."
                CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
              SOURCE_FIELD_REGION=>SOURCE_FIELD%REGION
              IF(ASSOCIATED(SOURCE_FIELD_REGION)) THEN                
                !Check the field is defined on the same region as the equations set
                IF(SOURCE_FIELD_REGION%USER_NUMBER/=REGION%USER_NUMBER) THEN
                  LOCAL_ERROR="Invalid region setup. The specified source field has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(SOURCE_FIELD_REGION%USER_NUMBER,"*",ERR,ERROR))// &
                    & " and the specified equations set has been created on region number "// &
                    & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
                !Check the specified source field has the same decomposition as the geometric field
                GEOMETRIC_FIELD=>EQUATIONS_SET%GEOMETRY%GEOMETRIC_FIELD
                IF(ASSOCIATED(GEOMETRIC_FIELD)) THEN
                  IF(.NOT.ASSOCIATED(GEOMETRIC_FIELD%DECOMPOSITION,SOURCE_FIELD%DECOMPOSITION)) THEN
                    CALL FlagError("The specified source field does not have the same decomposition as the geometric "// &
                      & "field for the specified equations set.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FlagError("The geometric field is not associated for the specified equations set.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FlagError("The specified source field region is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FlagError("The specified source field has not been finished.",ERR,ERROR,*999)
            ENDIF
          ELSE
            !Check the user number has not already been used for a field in this region.
            NULLIFY(FIELD)
            CALL FIELD_USER_NUMBER_FIND(SOURCE_FIELD_USER_NUMBER,REGION,FIELD,ERR,ERROR,*999)
            IF(ASSOCIATED(FIELD)) THEN
              LOCAL_ERROR="The specified source field user number of "// &
                & TRIM(NUMBER_TO_VSTRING(SOURCE_FIELD_USER_NUMBER,"*",ERR,ERROR))// &
                & "has already been used to create a field on region number "// &
                & TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))//"."
              CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ENDIF
          !Initialise the equations set source
          CALL EQUATIONS_SET_SOURCE_INITIALISE(EQUATIONS_SET,ERR,ERROR,*999)
          IF(.NOT.ASSOCIATED(SOURCE_FIELD)) EQUATIONS_SET%SOURCE%SOURCE_FIELD_AUTO_CREATED=.TRUE.
          !Initialise the setup
          CALL EQUATIONS_SET_SETUP_INITIALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          EQUATIONS_SET_SETUP_INFO%SETUP_TYPE=EQUATIONS_SET_SETUP_SOURCE_TYPE
          EQUATIONS_SET_SETUP_INFO%ACTION_TYPE=EQUATIONS_SET_SETUP_START_ACTION
          EQUATIONS_SET_SETUP_INFO%FIELD_USER_NUMBER=SOURCE_FIELD_USER_NUMBER
          EQUATIONS_SET_SETUP_INFO%FIELD=>SOURCE_FIELD
          !Start the equation set specific source setup
          CALL EQUATIONS_SET_SETUP(EQUATIONS_SET,EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Finalise the setup
          CALL EQUATIONS_SET_SETUP_FINALISE(EQUATIONS_SET_SETUP_INFO,ERR,ERROR,*999)
          !Set pointers
          IF(EQUATIONS_SET%SOURCE%SOURCE_FIELD_AUTO_CREATED) THEN            
            SOURCE_FIELD=>EQUATIONS_SET%SOURCE%SOURCE_FIELD
          ELSE
            EQUATIONS_SET%SOURCE%SOURCE_FIELD=>SOURCE_FIELD
          ENDIF
        ELSE
          CALL FlagError("Equation set region is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_SOURCE_CREATE_START")
    RETURN
999 CALL EQUATIONS_SET_SOURCE_FINALISE(EQUATIONS_SET%SOURCE,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_SOURCE_CREATE_START",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_SOURCE_CREATE_START

  !
  !================================================================================================================================
  !

  !>Destroy the source for an equations set. \see OPENCMISS::CMISSEquationsSetSourceDestroy
  SUBROUTINE EQUATIONS_SET_SOURCE_DESTROY(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to destroy the source for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_SOURCE_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%SOURCE)) THEN
        CALL EQUATIONS_SET_SOURCE_FINALISE(EQUATIONS_SET%SOURCE,ERR,ERROR,*999)
      ELSE
        CALL FlagError("Equations set source is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",ERR,ERROR,*999)
    ENDIF
       
    EXITS("EQUATIONS_SET_SOURCE_DESTROY")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_SOURCE_DESTROY",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_SOURCE_DESTROY

  !
  !================================================================================================================================
  !

  !>Finalise the source for a equations set and deallocate all memory.
  SUBROUTINE EQUATIONS_SET_SOURCE_FINALISE(EQUATIONS_SET_SOURCE,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_SOURCE_TYPE), POINTER :: EQUATIONS_SET_SOURCE !<A pointer to the equations set source to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SET_SOURCE_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET_SOURCE)) THEN
       DEALLOCATE(EQUATIONS_SET_SOURCE)
    ENDIF
       
    EXITS("EQUATIONS_SET_SOURCE_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_SOURCE_FINALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_SOURCE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the source for an equations set.
  SUBROUTINE EQUATIONS_SET_SOURCE_INITIALISE(EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to initialise the source field for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    ENTERS("EQUATIONS_SET_SOURCE_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(ASSOCIATED(EQUATIONS_SET%SOURCE)) THEN
        CALL FlagError("Source is already associated for this equations set.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(EQUATIONS_SET%SOURCE,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate equations set source.",ERR,ERROR,*999)
        EQUATIONS_SET%SOURCE%EQUATIONS_SET=>EQUATIONS_SET
        EQUATIONS_SET%SOURCE%SOURCE_FINISHED=.FALSE.
        EQUATIONS_SET%SOURCE%SOURCE_FIELD_AUTO_CREATED=.FALSE.
        NULLIFY(EQUATIONS_SET%SOURCE%SOURCE_FIELD)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*998)
    ENDIF
       
    EXITS("EQUATIONS_SET_SOURCE_INITIALISE")
    RETURN
999 CALL EQUATIONS_SET_SOURCE_FINALISE(EQUATIONS_SET%SOURCE,DUMMY_ERR,DUMMY_ERROR,*998)
998 ERRORSEXITS("EQUATIONS_SET_SOURCE_INITIALISE",ERR,ERROR)
    RETURN 1
    
  END SUBROUTINE EQUATIONS_SET_SOURCE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the equations set specification i.e., equations set class, type and subtype for an equations set. \see OPENCMISS::CMISSEquationsSetSpecificationGet
  SUBROUTINE EquationsSet_SpecificationGet(equationsSet,equationsSetSpecification,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set to get the specification for
    INTEGER(INTG), INTENT(INOUT) :: equationsSetSpecification(:) !<On return, The equations set specifcation array. Must be allocated on entry.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: specificationLength,specificationIdx
    TYPE(VARYING_STRING) :: localError

    ENTERS("EquationsSet_SpecificationGet",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      IF(equationsSet%equations_set_finished) THEN
        specificationLength=0
        DO specificationIdx=1,SIZE(equationsSet%specification,1)
          IF(equationsSet%specification(specificationIdx)>0) THEN
            specificationLength=specificationIdx
          END IF
        END DO
        IF(SIZE(equationsSetSpecification,1)>=specificationLength) THEN
          equationsSetSpecification(1:specificationLength)=equationsSet%specification(1:specificationLength)
        ELSE
          localError="The equations set specification array size is "//TRIM(NumberToVstring(specificationLength,"*",err,error))// &
            & " and it needs to be >= "//TRIM(NumberToVstring(SIZE(equationsSetSpecification,1),"*",err,error))//"."
          CALL FlagError(localError,err,error,*999)
        END IF
      ELSE
        CALL FlagError("Equations set has not been finished.",err,error,*999)
      END IF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    END IF

    EXITS("EquationsSet_SpecificationGet")
    RETURN
999 ERRORS("EquationsSet_SpecificationGet",err,error)
    EXITS("EquationsSet_SpecificationGet")
    RETURN 1
    
  END SUBROUTINE EquationsSet_SpecificationGet

  !
  !================================================================================================================================
  !

  !>Gets the size of the equations set specification array for a problem identified by a pointer. \see OPENCMISS::cmfe_EquationsSetSpecificationSizeGet
  SUBROUTINE EquationsSet_SpecificationSizeGet(equationsSet,specificationSize,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations Set to get the specification for.
    INTEGER(INTG), INTENT(OUT) :: specificationSize !<On return, the size of the problem specifcation array.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables

    ENTERS("EquationsSet_SpecificationSizeGet",err,error,*999)

    specificationSize=0
    IF(ASSOCIATED(equationsSet)) THEN
      IF(equationsSet%equations_set_finished) THEN
        IF(.NOT.ALLOCATED(equationsSet%specification)) THEN
          CALL FlagError("Equations set specification is not allocated.",err,error,*999)
        END IF
        specificationSize=SIZE(equationsSet%specification,1)
      ELSE
        CALL FlagError("Equations set has not been finished.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    ENDIF

    EXITS("EquationsSet_SpecificationSizeGet")
    RETURN
999 ERRORSEXITS("EquationsSet_SpecificationSizeGet",err,error)
    RETURN 1
    
  END SUBROUTINE EquationsSet_SpecificationSizeGet

  !
  !================================================================================================================================
  !

  !>Calculates a derived variable value for the equations set. \see OPENCMISS::CMISSEquationsSet_DerivedVariableCalculate
  SUBROUTINE EquationsSet_DerivedVariableCalculate(equationsSet,derivedType,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER, INTENT(IN) :: equationsSet !<A pointer to the equations set to calculate output for
    INTEGER(INTG), INTENT(IN) :: derivedType !<The derived value type to calculate. \see EQUATIONS_SET_CONSTANTS_DerivedTypes.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string

    ENTERS("EquationsSet_DerivedVariableCalculate",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      IF(.NOT.equationsSet%EQUATIONS_SET_FINISHED) THEN
        CALL FlagError("Equations set has not been finished.",err,error,*999)
      ELSE
        IF(.NOT.ALLOCATED(equationsSet%specification)) THEN
          CALL FlagError("Equations set specification is not allocated.",err,error,*999)
        ELSE IF(SIZE(equationsSet%specification,1)<1) THEN
          CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
        END IF
        SELECT CASE(equationsSet%specification(1))
        CASE(EQUATIONS_SET_ELASTICITY_CLASS)
          CALL Elasticity_EquationsSetDerivedVariableCalculate(equationsSet,derivedType,err,error,*999)
        CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_FITTING_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_MODAL_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
          CALL FlagError("Not implemented.",ERR,ERROR,*999)
        CASE DEFAULT
          CALL FlagError("The first equations set specification of "// &
            & TRIM(NUMBER_TO_VSTRING(equationsSet%specification(1),"*",ERR,ERROR))// &
            & " is not valid.",ERR,ERROR,*999)
        END SELECT
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    ENDIF

    EXITS("EquationsSet_DerivedVariableCalculate")
    RETURN
999 ERRORSEXITS("EquationsSet_DerivedVariableCalculate",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_DerivedVariableCalculate

  !
  !================================================================================================================================
  !

  !>Sets the field variable type of the derived field to be used to store a derived variable. \see OPENCMISS::CMISSEquationsSet_DerivedVariableSet
  SUBROUTINE EquationsSet_DerivedVariableSet(equationsSet,derivedType,fieldVariableType,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER, INTENT(IN) :: equationsSet !<A pointer to the equations set to calculate a derived field for
    INTEGER(INTG), INTENT(IN) :: derivedType !<The derived value type to calculate. \see EQUATIONS_SET_CONSTANTS_DerivedTypes.
    INTEGER(INTG), INTENT(IN) :: fieldVariableType !<The field variable type used to store the calculated derived value
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string

    ENTERS("EquationsSet_DerivedVariableSet",err,error,*999)

    !Check pointers and finished state
    IF(ASSOCIATED(equationsSet)) THEN
      IF(equationsSet%EQUATIONS_SET_FINISHED) THEN
        IF(ASSOCIATED(equationsSet%derived)) THEN
          IF(equationsSet%derived%derivedFinished) THEN
            CALL FlagError("Equations set derived information is already finished.",err,error,*999)
          END IF
        ELSE
          CALL FlagError("Equations set derived information is not associated.",err,error,*999)
        END IF
      ELSE
        CALL FlagError("Equations set has not been finished.",err,error,*999)
      END IF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    ENDIF

    IF(derivedType>0.AND.derivedType<=EQUATIONS_SET_NUMBER_OF_DERIVED_TYPES) THEN
      IF(fieldVariableType>0.AND.fieldVariableType<=FIELD_NUMBER_OF_VARIABLE_TYPES) THEN
        IF(equationsSet%derived%variableTypes(derivedType)==0) THEN
          equationsSet%derived%numberOfVariables=equationsSet%derived%numberOfVariables+1
        END IF
        equationsSet%derived%variableTypes(derivedType)=fieldVariableType
      ELSE
        CALL FlagError("The field variable type of "//TRIM(NUMBER_TO_VSTRING(fieldVariableType,"*",err,error))// &
          & " is invalid. It should be between 1 and "//TRIM(NUMBER_TO_VSTRING(FIELD_NUMBER_OF_VARIABLE_TYPES,"*", &
          & err,error))//" inclusive.",err,error,*999)
      END IF
    ELSE
      CALL FlagError("The derived variable type of "//TRIM(NUMBER_TO_VSTRING(derivedType,"*",err,error))// &
        & " is invalid. It should be between 1 and "//TRIM(NUMBER_TO_VSTRING(EQUATIONS_SET_NUMBER_OF_DERIVED_TYPES,"*", &
        & err,error))//" inclusive.",err,error,*999)
    END IF

    EXITS("EquationsSet_DerivedVariableSet")
    RETURN
999 ERRORSEXITS("EquationsSet_DerivedVariableSet",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_DerivedVariableSet
  !
  !================================================================================================================================
  !

  !>Sets/changes the equations set specification i.e., equations set class, type and subtype for an equations set. \see OPENCMISS::CMISSEquationsSetSpecificationSet
  SUBROUTINE EquationsSet_SpecificationSet(equationsSet,specification,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set to set the specification for
    INTEGER(INTG), INTENT(IN) :: specification(:) !<The equations set specification array to set
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: localError

    ENTERS("EquationsSet_SpecificationSet",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      IF(equationsSet%equations_set_finished) THEN
        CALL FlagError("Equations set has been finished.",err,error,*999)
      ELSE
        IF(SIZE(specification,1)<1) THEN
          CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
        END IF
        SELECT CASE(specification(1))
        CASE(EQUATIONS_SET_ELASTICITY_CLASS)
          CALL Elasticity_EquationsSetSpecificationSet(equationsSet,specification,err,error,*999)
        CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
          CALL FluidMechanics_EquationsSetSpecificationSet(equationsSet,specification,err,error,*999)
        CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
          CALL FlagError("Not implemented.",err,error,*999)
        CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
          CALL ClassicalField_EquationsSetSpecificationSet(equationsSet,specification,err,error,*999)
        CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
          IF(SIZE(specification,1)<2) THEN
            CALL FlagError("Equations set specification must have at least two entries for a bioelectrics equation class.", &
              & err,error,*999)
          END IF
          IF(specification(2)==EQUATIONS_SET_MONODOMAIN_STRANG_SPLITTING_EQUATION_TYPE) THEN
            CALL Monodomain_EquationsSetSpecificationSet(equationsSet,specification,err,error,*999)
          ELSE
            CALL Bioelectric_EquationsSetSpecificationSet(equationsSet,specification,err,error,*999)
          END IF
        CASE(EQUATIONS_SET_MODAL_CLASS)
          CALL FlagError("Not implemented.",err,error,*999)
        CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
          CALL MultiPhysics_EquationsSetSpecificationSet(equationsSet,specification,err,error,*999)
        CASE(EQUATIONS_SET_FITTING_CLASS)
          CALL Fitting_EquationsSetSpecificationSet(equationsSet,specification,err,error,*999)
        CASE(EQUATIONS_SET_OPTIMISATION_CLASS)
          CALL FlagError("Not implemented.",err,error,*999)
        CASE DEFAULT
          localError="The first equations set specification of "// &
            & TRIM(NumberToVstring(specification(1),"*",err,error))//" is not valid."
          CALL FlagError(localError,err,error,*999)
        END SELECT
      END IF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    END IF

    EXITS("EquationsSet_SpecificationSet")
    RETURN
999 ERRORS("EquationsSet_SpecificationSet",err,error)
    EXITS("EquationsSet_SpecificationSet")
    RETURN 1
    
  END SUBROUTINE EquationsSet_SpecificationSet
  
  !
  !================================================================================================================================
  !

  !>Calculate the strain tensor at a given element xi location.
  SUBROUTINE EquationsSet_StrainInterpolateXi(equationsSet,userElementNumber,xi,values,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER, INTENT(IN) :: equationsSet !<A pointer to the equations set to interpolate strain for.
    INTEGER(INTG), INTENT(IN) :: userElementNumber !<The user element number of the field to interpolate.
    REAL(DP), INTENT(IN) :: xi(:) !<The element xi to interpolate the field at.
    REAL(DP), INTENT(OUT) :: values(6) !<The interpolated strain tensor values.
    INTEGER(INTG), INTENT(OUT) :: err !<The error code.
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string

    ENTERS("EquationsSet_StrainInterpolateXi",err,error,*999)

    IF(.NOT.ASSOCIATED(equationsSet)) THEN
      CALL FlagError("Equations set is not associated.",err,error,*999)
    END IF
    IF(.NOT.equationsSet%equations_set_finished) THEN
      CALL FlagError("Equations set has not been finished.",err,error,*999)
    END IF
    IF(.NOT.ALLOCATED(equationsSet%specification)) THEN
      CALL FlagError("Equations set specification is not allocated.",err,error,*999)
    ELSE IF(SIZE(equationsSet%specification,1)<1) THEN
      CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
    END IF

    SELECT CASE(equationsSet%specification(1))
    CASE(EQUATIONS_SET_ELASTICITY_CLASS)
      CALL Elasticity_StrainInterpolateXi(equationsSet,userElementNumber,xi,values,err,error,*999)
    CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
      CALL FlagError("Not implemented.",err,error,*999)
    CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
      CALL FlagError("Not implemented.",err,error,*999)
    CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
      CALL FlagError("Not implemented.",err,error,*999)
    CASE(EQUATIONS_SET_MODAL_CLASS)
      CALL FlagError("Not implemented.",err,error,*999)
    CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
      CALL FlagError("Not implemented.",err,error,*999)
    CASE(EQUATIONS_SET_FITTING_CLASS)
      CALL FlagError("Not implemented.",err,error,*999)
    CASE(EQUATIONS_SET_OPTIMISATION_CLASS)
      CALL FlagError("Not implemented.",err,error,*999)
    CASE DEFAULT
      CALL FlagError("The first equations set specification of "// &
        & TRIM(NumberToVstring(equationsSet%specification(1),"*",err,error))// &
        & " is not valid.",err,error,*999)
    END SELECT

    EXITS("EquationsSet_StrainInterpolateXi")
    RETURN
999 ERRORSEXITS("EquationsSet_StrainInterpolateXi",err,error)
    RETURN 1
    
  END SUBROUTINE EquationsSet_StrainInterpolateXi

  !
  !================================================================================================================================
  !

  !>Finds and returns in EQUATIONS_SET a pointer to the equations set identified by USER_NUMBER in the given REGION. If no equations set with that USER_NUMBER exists EQUATIONS_SET is left nullified.
  SUBROUTINE EQUATIONS_SET_USER_NUMBER_FIND(USER_NUMBER,REGION,EQUATIONS_SET,ERR,ERROR,*)

    !Argument variables 
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number to find the equation set
    TYPE(REGION_TYPE), POINTER :: REGION !<The region to find the equations set in
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<On return, a pointer to the equations set if an equations set with the specified user number exists in the given region. If no equation set with the specified number exists a NULL pointer is returned. The pointer must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: equations_set_idx
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("EQUATIONS_SET_USER_NUMBER_FIND",ERR,ERROR,*999)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(EQUATIONS_SET)) THEN
        CALL FlagError("Equations set is already associated.",ERR,ERROR,*999)
      ELSE
        NULLIFY(EQUATIONS_SET)
        IF(ASSOCIATED(REGION%EQUATIONS_SETS)) THEN
          equations_set_idx=1
          DO WHILE(equations_set_idx<=REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS.AND..NOT.ASSOCIATED(EQUATIONS_SET))
            IF(REGION%EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR%USER_NUMBER==USER_NUMBER) THEN
              EQUATIONS_SET=>REGION%EQUATIONS_SETS%EQUATIONS_SETS(equations_set_idx)%PTR
            ELSE
              equations_set_idx=equations_set_idx+1
            ENDIF
          ENDDO
        ELSE
          LOCAL_ERROR="The equations sets on region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))// &
            & " are not associated."
          CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FlagError("Region is not associated.",ERR,ERROR,*999)
    ENDIF
    
    EXITS("EQUATIONS_SET_USER_NUMBER_FIND")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_USER_NUMBER_FIND",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SET_USER_NUMBER_FIND

  !
  !================================================================================================================================
  !

  !>Finalises all equations sets on a region and deallocates all memory.
  SUBROUTINE EQUATIONS_SETS_FINALISE(REGION,ERR,ERROR,*)

    !Argument variables
    TYPE(REGION_TYPE), POINTER :: REGION !<A pointer to the region to finalise the problems for.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SETS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(REGION%EQUATIONS_SETS)) THEN
        DO WHILE(REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS>0)
          CALL EQUATIONS_SET_DESTROY(REGION%EQUATIONS_SETS%EQUATIONS_SETS(1)%PTR,ERR,ERROR,*999)
        ENDDO !problem_idx
        DEALLOCATE(REGION%EQUATIONS_SETS)
      ENDIF
    ELSE
      CALL FlagError("Region is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("EQUATIONS_SETS_FINALISE")
    RETURN
999 ERRORSEXITS("EQUATIONS_SETS_FINALISE",ERR,ERROR)
    RETURN 1   
  END SUBROUTINE EQUATIONS_SETS_FINALISE

  !
  !================================================================================================================================
  !

  !>Intialises all equations sets on a region.
  SUBROUTINE EQUATIONS_SETS_INITIALISE(REGION,ERR,ERROR,*)

    !Argument variables
    TYPE(REGION_TYPE), POINTER :: REGION !<A pointer to the region to initialise the equations sets for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    ENTERS("EQUATIONS_SETS_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(REGION%EQUATIONS_SETS)) THEN
        CALL FlagError("Region already has associated equations sets",ERR,ERROR,*998)
      ELSE
!!TODO: Inherit any equations sets from the parent region???
        ALLOCATE(REGION%EQUATIONS_SETS,STAT=ERR)
        IF(ERR/=0) CALL FlagError("Could not allocate region equations sets",ERR,ERROR,*999)
        REGION%EQUATIONS_SETS%REGION=>REGION
        REGION%EQUATIONS_SETS%NUMBER_OF_EQUATIONS_SETS=0
        NULLIFY(REGION%EQUATIONS_SETS%EQUATIONS_SETS)
      ENDIF
    ELSE
      CALL FlagError("Region is not associated.",ERR,ERROR,*998)
    ENDIF

    EXITS("EQUATIONS_SETS_INITIALISE")
    RETURN
999 IF(ASSOCIATED(REGION%EQUATIONS_SETS)) DEALLOCATE(REGION%EQUATIONS_SETS)
998 ERRORSEXITS("EQUATIONS_SETS_INITIALISE",ERR,ERROR)
    RETURN 1
  END SUBROUTINE EQUATIONS_SETS_INITIALISE
  
  !
  !================================================================================================================================
  !

  !> Apply the boundary condition load increment to dependent field
  SUBROUTINE EQUATIONS_SET_BOUNDARY_CONDITIONS_INCREMENT(EQUATIONS_SET,BOUNDARY_CONDITIONS,ITERATION_NUMBER, &
    & MAXIMUM_NUMBER_OF_ITERATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS !<The boundary conditions to apply the increment to
    INTEGER(INTG), INTENT(IN) :: ITERATION_NUMBER !<The current load increment iteration index
    INTEGER(INTG), INTENT(IN) :: MAXIMUM_NUMBER_OF_ITERATIONS !<Final index for load increment loop
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    !Local variables
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DEPENDENT_VARIABLE
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: DOMAIN_MAPPING
    TYPE(BOUNDARY_CONDITIONS_VARIABLE_TYPE), POINTER :: BOUNDARY_CONDITIONS_VARIABLE
    TYPE(BOUNDARY_CONDITIONS_DIRICHLET_TYPE), POINTER :: DIRICHLET_BOUNDARY_CONDITIONS
    TYPE(BOUNDARY_CONDITIONS_PRESSURE_INCREMENTED_TYPE), POINTER :: PRESSURE_INCREMENTED_BOUNDARY_CONDITIONS
    INTEGER(INTG) :: variable_idx,variable_type,dirichlet_idx,dirichlet_dof_idx,neumann_point_dof
    INTEGER(INTG) :: condition_idx, condition_global_dof, condition_local_dof, MY_COMPUTATIONAL_NODE_NUMBER
    REAL(DP), POINTER :: FULL_LOADS(:),CURRENT_LOADS(:), PREV_LOADS(:)
    REAL(DP) :: FULL_LOAD, CURRENT_LOAD, NEW_LOAD, PREV_LOAD
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    ENTERS("EQUATIONS_SET_BOUNDARY_CONDITIONS_INCREMENT",ERR,ERROR,*999)

    NULLIFY(DEPENDENT_FIELD)
    NULLIFY(DEPENDENT_VARIABLE)
    NULLIFY(BOUNDARY_CONDITIONS_VARIABLE)
    NULLIFY(DIRICHLET_BOUNDARY_CONDITIONS)
    NULLIFY(FULL_LOADS)
    NULLIFY(PREV_LOADS)
    NULLIFY(CURRENT_LOADS)

    MY_COMPUTATIONAL_NODE_NUMBER=COMPUTATIONAL_NODE_NUMBER_GET(ERR,ERROR)
    
    !Take the stored load, scale it down appropriately then apply to the unknown variables
    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      IF(DIAGNOSTICS1) THEN
        CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  equations set",EQUATIONS_SET%USER_NUMBER,ERR,ERROR,*999)
      ENDIF
      IF(ASSOCIATED(BOUNDARY_CONDITIONS)) THEN
        DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
        IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
          IF(ALLOCATED(DEPENDENT_FIELD%VARIABLES)) THEN
            !Loop over the variables associated with this equations set
            !\todo: Looping over all field variables is not safe when volume-coupled problem is solved. Look at matrix and rhs mapping instead?
            DO variable_idx=1,DEPENDENT_FIELD%NUMBER_OF_VARIABLES
              DEPENDENT_VARIABLE=>DEPENDENT_FIELD%VARIABLES(variable_idx)
              variable_type=DEPENDENT_VARIABLE%VARIABLE_TYPE
              CALL BOUNDARY_CONDITIONS_VARIABLE_GET(BOUNDARY_CONDITIONS,DEPENDENT_VARIABLE,BOUNDARY_CONDITIONS_VARIABLE, &
                & ERR,ERROR,*999)
              IF(ASSOCIATED(BOUNDARY_CONDITIONS_VARIABLE)) THEN
                DOMAIN_MAPPING=>DEPENDENT_VARIABLE%DOMAIN_MAPPING
                IF(ASSOCIATED(DOMAIN_MAPPING)) THEN

                  ! Check if there are any incremented conditions applied for this boundary conditions variable
                  IF(BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS(BOUNDARY_CONDITION_FIXED_INCREMENTED)>0.OR. &
                      & BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS(BOUNDARY_CONDITION_MOVED_WALL_INCREMENTED)>0) THEN
                    IF(ASSOCIATED(BOUNDARY_CONDITIONS_VARIABLE%DIRICHLET_BOUNDARY_CONDITIONS)) THEN
                      DIRICHLET_BOUNDARY_CONDITIONS=>BOUNDARY_CONDITIONS_VARIABLE%DIRICHLET_BOUNDARY_CONDITIONS
                      !Get the pointer to vector holding the full and current loads
                      !   full load: FIELD_BOUNDARY_CONDITIONS_SET_TYPE - holds the target load values
                      !   current load: FIELD_VALUES_SET_TYPE - holds the current increment values
                      CALL Field_ParameterSetDataGet(DEPENDENT_FIELD,variable_type,FIELD_BOUNDARY_CONDITIONS_SET_TYPE, &
                        & FULL_LOADS,ERR,ERROR,*999)
                      !chrm 22/06/2010: 'FIELD_BOUNDARY_CONDITIONS_SET_TYPE' does not get updated with time (update_BCs)
                      !\ToDo: How can this be achieved ???
  !                     write(*,*)'FULL_LOADS = ',FULL_LOADS
                      CALL Field_ParameterSetDataGet(DEPENDENT_FIELD,variable_type,FIELD_VALUES_SET_TYPE, &
                        & CURRENT_LOADS,ERR,ERROR,*999)
  !                     write(*,*)'CURRENT_LOADS = ',CURRENT_LOADS
                      !Get full increment, calculate new load, then apply to dependent field
                      DO dirichlet_idx=1,BOUNDARY_CONDITIONS_VARIABLE%NUMBER_OF_DIRICHLET_CONDITIONS
                        dirichlet_dof_idx=DIRICHLET_BOUNDARY_CONDITIONS%DIRICHLET_DOF_INDICES(dirichlet_idx)
                        !Check whether we have an incremented boundary condition type
                        SELECT CASE(BOUNDARY_CONDITIONS_VARIABLE%CONDITION_TYPES(dirichlet_dof_idx))
                        CASE(BOUNDARY_CONDITION_FIXED_INCREMENTED, &
                            & BOUNDARY_CONDITION_MOVED_WALL_INCREMENTED)
                          !Convert dof index to local index
                          IF(DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(dirichlet_dof_idx)%DOMAIN_NUMBER(1)== &
                            & MY_COMPUTATIONAL_NODE_NUMBER) THEN
                            dirichlet_dof_idx=DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(dirichlet_dof_idx)%LOCAL_NUMBER(1)
                            IF(0<dirichlet_dof_idx.AND.dirichlet_dof_idx<DOMAIN_MAPPING%GHOST_START) THEN
                              FULL_LOAD=FULL_LOADS(dirichlet_dof_idx)
                              ! Apply full load if last step, or fixed BC
                              IF(ITERATION_NUMBER==MAXIMUM_NUMBER_OF_ITERATIONS) THEN
                                CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type,FIELD_VALUES_SET_TYPE, &
                                  & dirichlet_dof_idx,FULL_LOAD,ERR,ERROR,*999)
                              ELSE
                                !Calculate new load and apply to dependent field
                                CURRENT_LOAD=CURRENT_LOADS(dirichlet_dof_idx)
                                NEW_LOAD=CURRENT_LOAD+(FULL_LOAD-CURRENT_LOAD)/(MAXIMUM_NUMBER_OF_ITERATIONS-ITERATION_NUMBER+1)
                                CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type,FIELD_VALUES_SET_TYPE, &
                                  & dirichlet_dof_idx,NEW_LOAD,ERR,ERROR,*999)
                                IF(DIAGNOSTICS1) THEN
                                  CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  dof idx",dirichlet_dof_idx,ERR,ERROR,*999)
                                  CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    current load",CURRENT_LOAD,ERR,ERROR,*999)
                                  CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    new load",NEW_LOAD,ERR,ERROR,*999)
                                ENDIF
                              ENDIF !Full or intermediate load
                            ENDIF !non-ghost dof
                          ENDIF !current domain
                        CASE DEFAULT
                          !Do nothing for non-incremented boundary conditions
                        END SELECT
                      ENDDO !dirichlet_idx
  !---tob
                      !\ToDo: What happens if the call below is issued
                      !without actually that the dependent field has been modified in above conditional ?
                      CALL Field_ParameterSetUpdateStart(DEPENDENT_FIELD, &
                        & variable_type, FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
                      CALL Field_ParameterSetUpdateFinish(DEPENDENT_FIELD, &
                        & variable_type, FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
  !---toe
                      !Restore the vector handles
                      CALL Field_ParameterSetDataRestore(DEPENDENT_FIELD,variable_type,FIELD_BOUNDARY_CONDITIONS_SET_TYPE, &
                        & FULL_LOADS,ERR,ERROR,*999)
                      CALL Field_ParameterSetDataRestore(DEPENDENT_FIELD,variable_type,FIELD_VALUES_SET_TYPE, &
                        & CURRENT_LOADS,ERR,ERROR,*999)
                    ELSE
                      LOCAL_ERROR="Dirichlet boundary condition for variable type "// &
                        & TRIM(NUMBER_TO_VSTRING(variable_type,"*",ERR,ERROR))//" is not associated."
                      CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ENDIF

                  ! Also increment any incremented Neumann point conditions
                  IF(BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS(BOUNDARY_CONDITION_NEUMANN_POINT_INCREMENTED)>0) THEN
                    IF(ASSOCIATED(BOUNDARY_CONDITIONS_VARIABLE%neumannBoundaryConditions)) THEN
                      ! The boundary conditions parameter set contains the full values and the
                      ! current incremented values are transferred to the point values vector
                      DO condition_idx=1,BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS(BOUNDARY_CONDITION_NEUMANN_POINT_INCREMENTED)+ &
                          & BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS(BOUNDARY_CONDITION_NEUMANN_POINT)
                        condition_global_dof=BOUNDARY_CONDITIONS_VARIABLE%neumannBoundaryConditions%setDofs(condition_idx)
                        ! condition_global_dof could be for non-incremented point Neumann condition
                        IF(BOUNDARY_CONDITIONS_VARIABLE%CONDITION_TYPES(condition_global_dof)/= &
                          & BOUNDARY_CONDITION_NEUMANN_POINT_INCREMENTED) CYCLE
                        IF(DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(condition_global_dof)%DOMAIN_NUMBER(1)== &
                          & MY_COMPUTATIONAL_NODE_NUMBER) THEN
                          condition_local_dof=DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(condition_global_dof)% &
                            & LOCAL_NUMBER(1)
                          neumann_point_dof=BOUNDARY_CONDITIONS_VARIABLE%neumannBoundaryConditions%pointDofMapping% &
                            & GLOBAL_TO_LOCAL_MAP(condition_idx)%LOCAL_NUMBER(1)
                          CALL FIELD_PARAMETER_SET_GET_LOCAL_DOF(DEPENDENT_FIELD,variable_type, &
                            & FIELD_BOUNDARY_CONDITIONS_SET_TYPE,condition_local_dof,FULL_LOAD,ERR,ERROR,*999)
                          CALL DISTRIBUTED_VECTOR_VALUES_SET(BOUNDARY_CONDITIONS_VARIABLE%neumannBoundaryConditions% &
                            & pointValues,neumann_point_dof,FULL_LOAD*(REAL(ITERATION_NUMBER)/REAL(MAXIMUM_NUMBER_OF_ITERATIONS)), &
                            & ERR,ERROR,*999)
                        END IF
                      END DO
                    ELSE
                      LOCAL_ERROR="Neumann boundary conditions for variable type "// &
                        & TRIM(NUMBER_TO_VSTRING(variable_type,"*",ERR,ERROR))//" are not associated even though"// &
                        & TRIM(NUMBER_TO_VSTRING(BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS( &
                        & BOUNDARY_CONDITION_NEUMANN_POINT_INCREMENTED), &
                        & '*',ERR,ERROR))//" conditions of this type has been counted."
                      CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                    END IF
                  END IF

                  !There might also be pressure incremented conditions
                  IF (BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS(BOUNDARY_CONDITION_PRESSURE_INCREMENTED)>0) THEN
                    ! handle pressure incremented boundary conditions
                    IF(ASSOCIATED(BOUNDARY_CONDITIONS_VARIABLE%PRESSURE_INCREMENTED_BOUNDARY_CONDITIONS)) THEN
                      PRESSURE_INCREMENTED_BOUNDARY_CONDITIONS=>BOUNDARY_CONDITIONS_VARIABLE% &
                        & PRESSURE_INCREMENTED_BOUNDARY_CONDITIONS
                      !Due to a variety of reasons, the pressure incremented type is setup differently to dirichlet conditions.
                      !We store two sets of vectors, the current and previous values
                      !   current: FIELD_PRESSURE_VALUES_SET_TYPE - always holds the current increment, even if not incremented
                      !   previous: FIELD_PREVIOUS_PRESSURE_SET_TYPE - holds the previously applied increment
                      !Grab the pointers for both
                      CALL Field_ParameterSetDataGet(DEPENDENT_FIELD,variable_type,FIELD_PREVIOUS_PRESSURE_SET_TYPE, &
                        & PREV_LOADS,ERR,ERROR,*999)
                      CALL Field_ParameterSetDataGet(DEPENDENT_FIELD,variable_type,FIELD_PRESSURE_VALUES_SET_TYPE, &
                        & CURRENT_LOADS,ERR,ERROR,*999)
                      !Calculate the new load, update the old load
                      IF(ITERATION_NUMBER==1) THEN
                        !On the first iteration, FIELD_PRESSURE_VALUES_SET_TYPE actually contains the full load
                        DO condition_idx=1,BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS( &
                            & BOUNDARY_CONDITION_PRESSURE_INCREMENTED)
                          !Global dof index
                          condition_global_dof=PRESSURE_INCREMENTED_BOUNDARY_CONDITIONS%PRESSURE_INCREMENTED_DOF_INDICES &
                            & (condition_idx)
                          !Must convert into local dof index
                          IF(DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(condition_global_dof)%DOMAIN_NUMBER(1)== &
                            & MY_COMPUTATIONAL_NODE_NUMBER) THEN
                            condition_local_dof=DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(condition_global_dof)% &
                              & LOCAL_NUMBER(1)
                            IF(0<condition_local_dof.AND.condition_local_dof<DOMAIN_MAPPING%GHOST_START) THEN
                              NEW_LOAD=CURRENT_LOADS(condition_local_dof)
                              NEW_LOAD=NEW_LOAD/MAXIMUM_NUMBER_OF_ITERATIONS
!if (condition_idx==1) write(*,*) "new load=",new_load
                              !Update current and previous loads
                              CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type, &
                                & FIELD_PRESSURE_VALUES_SET_TYPE,condition_local_dof,NEW_LOAD,ERR,ERROR,*999)
                              CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type, &
                                & FIELD_PREVIOUS_PRESSURE_SET_TYPE,condition_local_dof,0.0_dp,ERR,ERROR,*999)
                              IF(DIAGNOSTICS1) THEN
                                CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  dof idx", &
                                    & condition_local_dof,ERR,ERROR,*999)
                                CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    current load", &
                                    & CURRENT_LOADS(condition_local_dof),ERR,ERROR,*999)
                                CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    new load",NEW_LOAD,ERR,ERROR,*999)
                              ENDIF
                            ENDIF !Non-ghost dof
                          ENDIF !Current domain
                        ENDDO !condition_idx
                      ELSE
                        !Calculate the new load, keep the current load
                        DO condition_idx=1,BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS( &
                            & BOUNDARY_CONDITION_PRESSURE_INCREMENTED)
                          !This is global dof idx
                          condition_global_dof=PRESSURE_INCREMENTED_BOUNDARY_CONDITIONS%PRESSURE_INCREMENTED_DOF_INDICES &
                            & (condition_idx)
                          !Must convert into local dof index
                          IF(DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(condition_global_dof)%DOMAIN_NUMBER(1)== &
                            & MY_COMPUTATIONAL_NODE_NUMBER) THEN
                            condition_local_dof=DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(condition_global_dof)% &
                              & LOCAL_NUMBER(1)
                            IF(0<condition_local_dof.AND.condition_local_dof<DOMAIN_MAPPING%GHOST_START) THEN
                              PREV_LOAD=PREV_LOADS(condition_local_dof)
                              CURRENT_LOAD=CURRENT_LOADS(condition_local_dof)
                              NEW_LOAD=CURRENT_LOAD+(CURRENT_LOAD-PREV_LOAD)  !This may be subject to numerical errors...
!if (condition_idx==1) write(*,*) "new load=",new_load
                              !Update current and previous loads
                              CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type, &
                                & FIELD_PRESSURE_VALUES_SET_TYPE,condition_local_dof,NEW_LOAD,ERR,ERROR,*999)
                              CALL Field_ParameterSetUpdateLocalDOF(DEPENDENT_FIELD,variable_type, &
                                & FIELD_PREVIOUS_PRESSURE_SET_TYPE,condition_local_dof,CURRENT_LOAD,ERR,ERROR,*999)
                              IF(DIAGNOSTICS1) THEN
                                CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  dof idx", &
                                    & condition_local_dof,ERR,ERROR,*999)
                                CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    current load", &
                                    & CURRENT_LOADS(condition_local_dof),ERR,ERROR,*999)
                                CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"    new load",NEW_LOAD,ERR,ERROR,*999)
                              ENDIF
                            ENDIF !Non-ghost dof
                          ENDIF !Current domain
                        ENDDO !condition_idx
                      ENDIF
                      !Start transfer of dofs to neighbouring domains
                      CALL Field_ParameterSetUpdateStart(DEPENDENT_FIELD,variable_type,FIELD_PREVIOUS_PRESSURE_SET_TYPE, &
                        & ERR,ERROR,*999)
                      CALL Field_ParameterSetUpdateStart(DEPENDENT_FIELD,variable_type,FIELD_PRESSURE_VALUES_SET_TYPE, &
                        & ERR,ERROR,*999)
                      !Restore the vector handles
                      CALL Field_ParameterSetDataRestore(DEPENDENT_FIELD,variable_type,FIELD_PREVIOUS_PRESSURE_SET_TYPE, &
                        & PREV_LOADS,ERR,ERROR,*999)
                      CALL Field_ParameterSetDataRestore(DEPENDENT_FIELD,variable_type,FIELD_PRESSURE_VALUES_SET_TYPE, &
                        & CURRENT_LOADS,ERR,ERROR,*999)
                      !Finish transfer of dofs to neighbouring domains
                      CALL Field_ParameterSetUpdateFinish(DEPENDENT_FIELD,variable_type,FIELD_PREVIOUS_PRESSURE_SET_TYPE, &
                        & ERR,ERROR,*999)
                      CALL Field_ParameterSetUpdateFinish(DEPENDENT_FIELD,variable_type,FIELD_PRESSURE_VALUES_SET_TYPE, &
                        & ERR,ERROR,*999)
                    ELSE
                      LOCAL_ERROR="Pressure incremented boundary condition for variable type "// &
                        & TRIM(NUMBER_TO_VSTRING(variable_type,"*",ERR,ERROR))//" is not associated even though"// &
                        & TRIM(NUMBER_TO_VSTRING(BOUNDARY_CONDITIONS_VARIABLE%DOF_COUNTS(BOUNDARY_CONDITION_PRESSURE_INCREMENTED), &
                        & '*',ERR,ERROR))//" conditions of this type has been counted."
                      CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ENDIF !Pressure incremented bc block
                ELSE
                  LOCAL_ERROR="Domain mapping is not associated for variable "// &
                    & TRIM(NUMBER_TO_VSTRING(variable_type,"*",ERR,ERROR))//" of dependent field"
                  CALL FlagError(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF !Domain mapping test
              ELSE
                ! do nothing - no boundary conditions variable type associated?
              ENDIF
            ENDDO !variable_idx
          ELSE
            CALL FlagError("Dependent field variables are not allocated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FlagError("Dependent field is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FlagError("Boundary conditions are not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF

    EXITS("EQUATIONS_SET_BOUNDARY_CONDITIONS_INCREMENT")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_BOUNDARY_CONDITIONS_INCREMENT",ERR,ERROR)
    RETURN 1

  END SUBROUTINE EQUATIONS_SET_BOUNDARY_CONDITIONS_INCREMENT

  !
  !================================================================================================================================
  !

  !> Apply load increments for equations sets
  SUBROUTINE EQUATIONS_SET_LOAD_INCREMENT_APPLY(EQUATIONS_SET,BOUNDARY_CONDITIONS,ITERATION_NUMBER,MAXIMUM_NUMBER_OF_ITERATIONS, &
    & ERR,ERROR,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS !<The boundary conditions to apply the increment to
    INTEGER(INTG), INTENT(IN) :: ITERATION_NUMBER !<The current load increment iteration index
    INTEGER(INTG), INTENT(IN) :: MAXIMUM_NUMBER_OF_ITERATIONS !<Final index for load increment loop
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    ENTERS("EQUATIONS_SET_LOAD_INCREMENT_APPLY",ERR,ERROR,*999)

    IF(ASSOCIATED(EQUATIONS_SET)) THEN
      !Increment boundary conditions
      CALL EQUATIONS_SET_BOUNDARY_CONDITIONS_INCREMENT(EQUATIONS_SET,BOUNDARY_CONDITIONS,ITERATION_NUMBER, &
        & MAXIMUM_NUMBER_OF_ITERATIONS,ERR,ERROR,*999)

      !Apply any other equation set specific increments
      IF(.NOT.ALLOCATED(EQUATIONS_SET%SPECIFICATION)) THEN
        CALL FlagError("Equations set specification is not allocated.",err,error,*999)
      ELSE IF(SIZE(EQUATIONS_SET%SPECIFICATION,1)<1) THEN
        CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
      END IF
      SELECT CASE(EQUATIONS_SET%SPECIFICATION(1))
      CASE(EQUATIONS_SET_ELASTICITY_CLASS)
        CALL ELASTICITY_LOAD_INCREMENT_APPLY(EQUATIONS_SET,ITERATION_NUMBER,MAXIMUM_NUMBER_OF_ITERATIONS,ERR,ERROR,*999)
      CASE DEFAULT
        !Do nothing
      END SELECT
    ELSE
      CALL FlagError("Equations set is not associated.",ERR,ERROR,*999)
    ENDIF


    EXITS("EQUATIONS_SET_LOAD_INCREMENT_APPLY")
    RETURN
999 ERRORSEXITS("EQUATIONS_SET_LOAD_INCREMENT_APPLY",ERR,ERROR)
    RETURN 1

  END SUBROUTINE EQUATIONS_SET_LOAD_INCREMENT_APPLY

 !
  !================================================================================================================================
  !

  !>Assembles the equations stiffness matrix, residuals and rhs for a nonlinear static equations set using a nodal method
  SUBROUTINE EquationsSet_AssembleStaticNonlinearNodal(equationsSet,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set to assemble the equations for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: numberOfTimes
    INTEGER(INTG) :: nodeIdx,nodeNumber
    REAL(SP) :: nodeUserElapsed,nodeSystemElapsed,userElapsed,userTime1(1),userTime2(1),userTime3(1),userTime4(1), &
      & userTime5(1),userTime6(1),systemElapsed,systemTime1(1),systemTime2(1),systemTime3(1),systemTime4(1), &
      & systemTime5(1),systemTime6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: nodalMapping
    TYPE(EQUATIONS_TYPE), POINTER :: equations
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: equationsMatrices
    TYPE(FIELD_TYPE), POINTER :: dependentField
    
    ENTERS("EquationsSet_AssembleStaticNonlinearNodal",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      dependentField=>equationsSet%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(dependentField)) THEN
        equations=>equationsSet%EQUATIONS
        IF(ASSOCIATED(equations)) THEN
          equationsMatrices=>equations%EQUATIONS_MATRICES
          IF(ASSOCIATED(equationsMatrices)) THEN
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime1,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime1,err,error,*999)
            ENDIF
            !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(equationsMatrices,EQUATIONS_MATRICES_NONLINEAR_ONLY,0.0_DP,err,error,*999)
            !Allocate the nodal matrices 
            CALL EquationsMatrices_NodalInitialise(equationsMatrices,err,error,*999)
            nodalMapping=>dependentField%DECOMPOSITION%DOMAIN(dependentField%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%NODES
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime2,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime2,err,error,*999)
              userElapsed=userTime2(1)-userTime1(1)
              systemElapsed=systemTime2(1)-systemTime1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",systemElapsed, &
                & err,error,*999)
              nodeUserElapsed=0.0_SP
              nodeSystemElapsed=0.0_SP
            ENDIF
            numberOfTimes=0
            !Loop over the internal nodes
            DO nodeIdx=nodalMapping%INTERNAL_START,nodalMapping%INTERNAL_FINISH
              nodeNumber=nodalMapping%DOMAIN_LIST(nodeIdx)
              numberOfTimes=numberOfTimes+1
              CALL EquationsMatrices_NodalCalculate(equationsMatrices,nodeNumber,err,error,*999)
              CALL EquationsSet_NodalResidualEvaluate(equationsSet,nodeNumber,err,error,*999)
              CALL EquationsMatrices_NodeAdd(equationsMatrices,err,error,*999)
            ENDDO !nodeIdx
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime3,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime3,err,error,*999)
              userElapsed=userTime3(1)-userTime2(1)
              systemElapsed=systemTime3(1)-systemTime2(1)
              nodeUserElapsed=userElapsed
              nodeSystemElapsed=systemElapsed
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",systemElapsed, &
                & err,error,*999)
            ENDIF
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime4,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime4,err,error,*999)
              userElapsed=userTime4(1)-userTime3(1)
              systemElapsed=systemTime4(1)-systemTime3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",systemElapsed, &
                & err,error,*999)              
            ENDIF
            !Loop over the boundary and ghost nodes
            DO nodeIdx=nodalMapping%BOUNDARY_START,nodalMapping%GHOST_FINISH
              nodeNumber=nodalMapping%DOMAIN_LIST(nodeIdx)
              numberOfTimes=numberOfTimes+1
              CALL EquationsMatrices_NodalCalculate(equationsMatrices,nodeNumber,err,error,*999)
              CALL EquationsSet_NodalResidualEvaluate(equationsSet,nodeNumber,err,error,*999)
              CALL EquationsMatrices_NodeAdd(equationsMatrices,err,error,*999)
            ENDDO !nodeIdx
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime5,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime5,err,error,*999)
              userElapsed=userTime5(1)-userTime4(1)
              systemElapsed=systemTime5(1)-systemTime4(1)
              nodeUserElapsed=nodeUserElapsed+userElapsed
              nodeSystemElapsed=nodeSystemElapsed+userElapsed
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",systemElapsed, &
                & err,error,*999)
              IF(numberOfTimes>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average node user time for equations assembly = ", &
                  & nodeUserElapsed/numberOfTimes,err,error,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average node system time for equations assembly = ", &
                  & nodeSystemElapsed/numberOfTimes,err,error,*999)
              ENDIF
            ENDIF
            !Finalise the nodal matrices
            CALL EquationsMatrices_NodalFinalise(equationsMatrices,err,error,*999)
            !Output equations matrices and RHS vector if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,equationsMatrices,err,error,*999)
            ENDIF
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime6,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime6,err,error,*999)
              userElapsed=userTime6(1)-userTime1(1)
              systemElapsed=systemTime6(1)-systemTime1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",systemElapsed, &
                & err,error,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",err,error,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated",err,error,*999)
    ENDIF
       
    EXITS("EquationsSet_AssembleStaticNonlinearNodal")
    RETURN
999 ERRORSEXITS("EquationsSet_AssembleStaticNonlinearNodal",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_AssembleStaticNonlinearNodal

  !
  !================================================================================================================================
  !

  !>Evaluates the nodal Jacobian for the given node number for a nodal equations set.
  SUBROUTINE EquationsSet_NodalJacobianEvaluate(equationsSet,nodeNumber,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set
    INTEGER(INTG), INTENT(IN) :: nodeNumber !<The node number to evaluate the Jacobian for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code 
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: matrixIdx
    TYPE(NodalMatrixType), POINTER :: nodalMatrix
    TYPE(EQUATIONS_TYPE), POINTER :: equations
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: equationsMatrices
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: nonlinearMatrices
    TYPE(VARYING_STRING) :: localError
    
    ENTERS("EquationsSet_NodalJacobianEvaluate",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      equations=>equationsSet%EQUATIONS
      IF(ASSOCIATED(equations)) THEN
        equationsMatrices=>equations%EQUATIONS_MATRICES
        IF(ASSOCIATED(equationsMatrices)) THEN
          nonlinearMatrices=>equationsMatrices%NONLINEAR_MATRICES
          IF(ASSOCIATED(nonlinearMatrices)) THEN
            DO matrixIdx=1,nonlinearMatrices%NUMBER_OF_JACOBIANS
              SELECT CASE(nonlinearMatrices%JACOBIANS(matrixIdx)%PTR%JACOBIAN_CALCULATION_TYPE)
              CASE(EQUATIONS_JACOBIAN_ANALYTIC_CALCULATED)
                ! None of these routines currently support calculating off diagonal terms for coupled problems,
                ! but when one does we will have to pass through the matrixIdx parameter
                IF(matrixIdx>1) THEN
                  CALL FlagError("Analytic off-diagonal Jacobian calculation not implemented.",err,error,*999)
                END IF
                IF(.NOT.ALLOCATED(equationsSet%specification)) THEN
                  CALL FlagError("Equations set specification is not allocated.",err,error,*999)
                ELSE IF(SIZE(equationsSet%specification,1)<1) THEN
                  CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
                END IF
                SELECT CASE(equationsSet%specification(1))
                CASE(EQUATIONS_SET_ELASTICITY_CLASS)
                  CALL FlagError("Not implemented.",err,error,*999)
                CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
                  CALL FluidMechanics_NodalJacobianEvaluate(equationsSet,nodeNumber,err,error,*999)
                CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
                  CALL FlagError("Not implemented.",err,error,*999)
                CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
                  CALL FlagError("Not implemented.",err,error,*999)
                CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
                  CALL FlagError("Not implemented.",err,error,*999)
                CASE(EQUATIONS_SET_MODAL_CLASS)
                  CALL FlagError("Not implemented.",err,error,*999)
                CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
                  CALL FlagError("Not implemented.",err,error,*999)
                CASE DEFAULT
                  localError="The first equations set specification of "// &
                    & TRIM(NUMBER_TO_VSTRING(equationsSet%specification(1),"*", &
                    & err,error))//" is not valid."
                  CALL FlagError(localError,err,error,*999)
                END SELECT
              CASE(EQUATIONS_JACOBIAN_FINITE_DIFFERENCE_CALCULATED)
                CALL FlagError("Not implemented.",err,error,*999)
              CASE DEFAULT
                localError="Jacobian calculation type "//TRIM(NUMBER_TO_VSTRING(nonlinearMatrices%JACOBIANS(matrixIdx)%PTR% &
                  & JACOBIAN_CALCULATION_TYPE,"*",err,error))//" is not valid."
                CALL FlagError(localError,err,error,*999)
              END SELECT
            END DO
          ELSE
            CALL FlagError("Equations nonlinear matrices is not associated.",err,error,*999)
          END IF
        ELSE
          CALL FlagError("Equations matrices is not associated.",err,error,*999)
        END IF
        IF(equations%OUTPUT_TYPE>=EQUATIONS_NODAL_MATRIX_OUTPUT) THEN
          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",err,error,*999)
          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Nodal Jacobian matrix:",err,error,*999)
          CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Node number = ",nodeNumber,err,error,*999)
          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Nodal Jacobian:",err,error,*999)
          DO matrixIdx=1,nonlinearMatrices%NUMBER_OF_JACOBIANS
            CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Jacobian number = ",matrixIdx,err,error,*999)
            CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update Jacobian = ",nonlinearMatrices%JACOBIANS(matrixIdx)%PTR% &
              & UPDATE_JACOBIAN,err,error,*999)
            IF(nonlinearMatrices%JACOBIANS(matrixIdx)%PTR%UPDATE_JACOBIAN) THEN
              nodalMatrix=>nonlinearMatrices%JACOBIANS(matrixIdx)%PTR%NodalJacobian
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",nodalMatrix%numberOfRows,err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of columns = ",nodalMatrix%numberOfColumns, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",nodalMatrix%maxNumberOfRows, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of columns = ",nodalMatrix% &
                & maxNumberOfColumns,err,error,*999)
              CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalMatrix%numberOfRows,8,8,nodalMatrix%rowDofs, &
                & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',err,error,*999)
              CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalMatrix%numberOfColumns,8,8,nodalMatrix% &
                & columnDofs,'("  Column dofs  :",8(X,I13))','(16X,8(X,I13))',err,error,*999)
              CALL WRITE_STRING_MATRIX(GENERAL_OUTPUT_TYPE,1,1,nodalMatrix%numberOfRows,1,1,nodalMatrix% &
                & numberOfColumns,8,8,nodalMatrix%matrix(1:nodalMatrix%numberOfRows,1:nodalMatrix% &
                & numberOfColumns),WRITE_STRING_MATRIX_NAME_AND_INDICES,'("  Matrix','(",I2,",:)',' :",8(X,E13.6))', &
                & '(16X,8(X,E13.6))',err,error,*999)
            END IF
          END DO
        END IF
      ELSE
        CALL FlagError("Equations is not associated.",err,error,*999)
      END IF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    END IF

    EXITS("EquationsSet_NodalJacobianEvaluate")
    RETURN
999 ERRORSEXITS("EquationsSet_NodalJacobianEvaluate",err,error)
    RETURN 1

  END SUBROUTINE EquationsSet_NodalJacobianEvaluate

  !
  !================================================================================================================================
  !

  !>Evaluates the nodal residual and rhs vector for the given node number for a nodal equations set.
  SUBROUTINE EquationsSet_NodalResidualEvaluate(equationsSet,nodeNumber,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set
    INTEGER(INTG), INTENT(IN) :: nodeNumber !<The nodal number to evaluate the residual for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code 
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: matrixIdx
    TYPE(NodalMatrixType), POINTER :: nodalMatrix
    TYPE(NodalVectorType), POINTER :: nodalVector
    TYPE(EQUATIONS_TYPE), POINTER :: equations
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: equationsMatrices
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: linearMatrices
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: nonlinearMatrices
    TYPE(EQUATIONS_MATRICES_RHS_TYPE), POINTER :: rhsVector
    TYPE(EQUATIONS_MATRICES_SOURCE_TYPE), POINTER :: sourceVector
    TYPE(VARYING_STRING) :: localError
    
    ENTERS("EquationsSet_NodalResidualEvaluate",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      IF(.NOT.ALLOCATED(equationsSet%specification)) THEN
        CALL FlagError("Equations set specification is not allocated.",err,error,*999)
      ELSE IF(SIZE(equationsSet%specification,1)<1) THEN
        CALL FlagError("Equations set specification must have at least one entry.",err,error,*999)
      END IF
      SELECT CASE(equationsSet%specification(1))
      CASE(EQUATIONS_SET_ELASTICITY_CLASS)
        CALL FlagError("Not implemented.",err,error,*999)
      CASE(EQUATIONS_SET_FLUID_MECHANICS_CLASS)
        CALL FluidMechanics_NodalResidualEvaluate(equationsSet,nodeNumber,err,error,*999)
      CASE(EQUATIONS_SET_ELECTROMAGNETICS_CLASS)
        CALL FlagError("Not implemented.",err,error,*999)
      CASE(EQUATIONS_SET_CLASSICAL_FIELD_CLASS)
        CALL FlagError("Not implemented.",err,error,*999)
      CASE(EQUATIONS_SET_BIOELECTRICS_CLASS)
        CALL FlagError("Not implemented.",err,error,*999)
      CASE(EQUATIONS_SET_MODAL_CLASS)
        CALL FlagError("Not implemented.",err,error,*999)
      CASE(EQUATIONS_SET_MULTI_PHYSICS_CLASS)
        CALL FlagError("Not implemented.",err,error,*999)
      CASE DEFAULT
        localError="The first equations set specification of "// &
          & TRIM(NUMBER_TO_VSTRING(equationsSet%specification(1),"*",err,error))//" is not valid."
        CALL FlagError(localError,err,error,*999)
      END SELECT
      equations=>equationsSet%EQUATIONS
      IF(ASSOCIATED(equations)) THEN
        equationsMatrices=>equations%EQUATIONS_MATRICES
        IF(ASSOCIATED(equationsMatrices)) THEN
          nonlinearMatrices=>equationsMatrices%NONLINEAR_MATRICES
          IF(ASSOCIATED(nonlinearMatrices)) THEN
            nonlinearMatrices%NodalResidualCalculated=nodeNumber
            IF(equations%OUTPUT_TYPE>=EQUATIONS_NODAL_MATRIX_OUTPUT) THEN
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",err,error,*999)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Nodal residual matrices and vectors:",err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Node number = ",nodeNumber,err,error,*999)
              linearMatrices=>equationsMatrices%LINEAR_MATRICES
              IF(ASSOCIATED(linearMatrices)) THEN
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Linear matrices:",err,error,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Number of node matrices = ",linearMatrices% &
                  & NUMBER_OF_LINEAR_MATRICES,err,error,*999)
                DO matrixIdx=1,linearMatrices%NUMBER_OF_LINEAR_MATRICES
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Node matrix : ",matrixIdx,err,error,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update matrix = ",linearMatrices%MATRICES(matrixIdx)%PTR% &
                    & UPDATE_MATRIX,err,error,*999)
                  IF(linearMatrices%MATRICES(matrixIdx)%PTR%UPDATE_MATRIX) THEN
                    nodalMatrix=>linearMatrices%MATRICES(matrixIdx)%PTR%NodalMatrix
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",nodalMatrix%numberOfRows,err,error,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of columns = ",nodalMatrix%numberOfColumns, &
                      & err,error,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",nodalMatrix%maxNumberOfRows, &
                      & err,error,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of columns = ",nodalMatrix% &
                      & maxNumberOfColumns,err,error,*999)
                    CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalMatrix%numberOfRows,8,8,nodalMatrix%rowDofs, &
                      & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',err,error,*999)
                    CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalMatrix%numberOfColumns,8,8,nodalMatrix% &
                      & columnDofs,'("  Column dofs  :",8(X,I13))','(16X,8(X,I13))',err,error,*999)
                    CALL WRITE_STRING_MATRIX(GENERAL_OUTPUT_TYPE,1,1,nodalMatrix%numberOfRows,1,1,nodalMatrix% &
                      & numberOfColumns,8,8,nodalMatrix%matrix(1:nodalMatrix%numberOfRows,1:nodalMatrix% &
                      & numberOfColumns),WRITE_STRING_MATRIX_NAME_AND_INDICES,'("  Matrix','(",I2,",:)',' :",8(X,E13.6))', &
                      & '(16X,8(X,E13.6))',err,error,*999)
                  ENDIF
                ENDDO !matrixIdx
              ENDIF
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Node residual vector:",err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update vector = ",nonlinearMatrices%UPDATE_RESIDUAL,err,error,*999)
              IF(nonlinearMatrices%UPDATE_RESIDUAL) THEN
                nodalVector=>nonlinearMatrices%NodalResidual
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",nodalVector%numberOfRows,err,error,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",nodalVector%maxNumberOfRows, &
                  & err,error,*999)
                CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalVector%numberOfRows,8,8,nodalVector%rowDofs, &
                  & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',err,error,*999)
                CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalVector%numberOfRows,8,8,nodalVector%vector, &
                  & '("  Vector(:)    :",8(X,E13.6))','(16X,8(X,E13.6))',err,error,*999)
              ENDIF
              rhsVector=>equationsMatrices%RHS_VECTOR
              IF(ASSOCIATED(rhsVector)) THEN
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Node RHS vector :",err,error,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update vector = ",rhsVector%UPDATE_VECTOR,err,error,*999)
                IF(rhsVector%UPDATE_VECTOR) THEN
                  nodalVector=>rhsVector%NodalVector
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",nodalVector%numberOfRows,err,error,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",nodalVector%maxNumberOfRows, &
                    & err,error,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalVector%numberOfRows,8,8,nodalVector%rowDofs, &
                    & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',err,error,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalVector%numberOfRows,8,8,nodalVector%vector, &
                    & '("  Vector(:)    :",8(X,E13.6))','(16X,8(X,E13.6))',err,error,*999)
                ENDIF
              ENDIF
              sourceVector=>equationsMatrices%SOURCE_VECTOR
              IF(ASSOCIATED(sourceVector)) THEN
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Node source vector :",err,error,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Update vector = ",sourceVector%UPDATE_VECTOR,err,error,*999)
                IF(sourceVector%UPDATE_VECTOR) THEN
                  nodalVector=>sourceVector%NodalVector
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of rows = ",nodalVector%numberOfRows,err,error,*999)
                  CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Maximum number of rows = ",nodalVector%maxNumberOfRows, &
                    & err,error,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalVector%numberOfRows,8,8,nodalVector%rowDofs, &
                    & '("  Row dofs     :",8(X,I13))','(16X,8(X,I13))',err,error,*999)
                  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,nodalVector%numberOfRows,8,8,nodalVector%vector, &
                    & '("  Vector(:)    :",8(X,E13.6))','(16X,8(X,E13.6))',err,error,*999)
                ENDIF
              ENDIF
            ENDIF
          ELSE
            CALL FlagError("Equation nonlinear matrices not associated.",err,error,*999)
          ENDIF
        ELSE
          CALL FlagError("Equation matrices is not associated.",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Equations is not associated.",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    ENDIF    
       
    EXITS("EquationsSet_NodalResidualEvaluate")
    RETURN
999 ERRORSEXITS("EquationsSet_NodalResidualEvaluate",err,error)
    RETURN 1
    
  END SUBROUTINE EquationsSet_NodalResidualEvaluate


  !
  !================================================================================================================================
  !

  !>Evaluates the Jacobian for an static equations set using the finite nodal method
  SUBROUTINE EquationsSet_JacobianEvaluateStaticNodal(equationsSet,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set to evaluate the Jacobian for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: numberOfTimes
    INTEGER(INTG) :: nodeIdx,nodeNumber
    REAL(SP) :: nodeUserElapsed,nodeSystemElapsed,userElapsed,userTime1(1),userTime2(1),userTime3(1),userTime4(1), &
      & userTime5(1),userTime6(1),systemElapsed,systemTime1(1),systemTime2(1),systemTime3(1),systemTime4(1), &
      & systemTime5(1),systemTime6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: nodalMapping
    TYPE(EQUATIONS_TYPE), POINTER :: equations
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: equationsMatrices
    TYPE(FIELD_TYPE), POINTER :: dependentField
  
    ENTERS("EquationsSet_JacobianEvaluateStaticNodal",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      dependentField=>equationsSet%DEPENDENT%DEPENDENT_FIELD
      IF(ASSOCIATED(dependentField)) THEN
        equations=>equationsSet%EQUATIONS
        IF(ASSOCIATED(equations)) THEN
          equationsMatrices=>equations%EQUATIONS_MATRICES
          IF(ASSOCIATED(equationsMatrices)) THEN
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime1,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime1,err,error,*999)
            ENDIF
            !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(equationsMatrices,EQUATIONS_MATRICES_JACOBIAN_ONLY,0.0_DP,err,error,*999)
            !Assemble the nodes
            !Allocate the nodal matrices 
            CALL EquationsMatrices_NodalInitialise(equationsMatrices,err,error,*999)
            nodalMapping=>dependentField%DECOMPOSITION%DOMAIN(dependentField%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%NODES
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime2,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime2,err,error,*999)
              userElapsed=userTime2(1)-userTime1(1)
              systemElapsed=systemTime2(1)-systemTime1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",systemElapsed, &
                & err,error,*999)
              nodeUserElapsed=0.0_SP
              nodeSystemElapsed=0.0_SP
            ENDIF
            numberOfTimes=0
            !Loop over the internal nodes
            DO nodeIdx=nodalMapping%INTERNAL_START,nodalMapping%INTERNAL_FINISH
              nodeNumber=nodalMapping%DOMAIN_LIST(nodeIdx)
              numberOfTimes=numberOfTimes+1
              CALL EquationsMatrices_NodalCalculate(equationsMatrices,nodeNumber,err,error,*999)
              CALL EquationsSet_NodalJacobianEvaluate(equationsSet,nodeNumber,err,error,*999)
              CALL EquationsMatrices_JacobianNodeAdd(equationsMatrices,err,error,*999)
            ENDDO !nodeIdx
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime3,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime3,err,error,*999)
              userElapsed=userTime3(1)-userTime2(1)
              systemElapsed=systemTime3(1)-systemTime2(1)
              nodeUserElapsed=userElapsed
              nodeSystemElapsed=systemElapsed
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",systemElapsed, &
                & err,error,*999)
            ENDIF
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime4,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime4,err,error,*999)
              userElapsed=userTime4(1)-userTime3(1)
              systemElapsed=systemTime4(1)-systemTime3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",systemElapsed, &
                & err,error,*999)              
            ENDIF
            !Loop over the boundary and ghost nodes
            DO nodeIdx=nodalMapping%BOUNDARY_START,nodalMapping%GHOST_FINISH
              nodeNumber=nodalMapping%DOMAIN_LIST(nodeIdx)
              numberOfTimes=numberOfTimes+1
              CALL EquationsMatrices_NodalCalculate(equationsMatrices,nodeNumber,err,error,*999)
              CALL EquationsSet_NodalJacobianEvaluate(equationsSet,nodeNumber,err,error,*999)
              CALL EquationsMatrices_JacobianNodeAdd(equationsMatrices,err,error,*999)
            ENDDO !nodeIdx
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime5,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime5,err,error,*999)
              userElapsed=userTime5(1)-userTime4(1)
              systemElapsed=systemTime5(1)-systemTime4(1)
              nodeUserElapsed=nodeUserElapsed+userElapsed
              nodeSystemElapsed=nodeSystemElapsed+userElapsed
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",systemElapsed, &
                & err,error,*999)
              IF(numberOfTimes>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average node user time for equations assembly = ", &
                  & nodeUserElapsed/numberOfTimes,err,error,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average node system time for equations assembly = ", &
                  & nodeSystemElapsed/numberOfTimes,err,error,*999)
              ENDIF
            ENDIF
            !Finalise the nodal matrices
            CALL EquationsMatrices_NodalFinalise(equationsMatrices,err,error,*999)
            !Output equations matrices and RHS vector if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_JACOBIAN_OUTPUT(GENERAL_OUTPUT_TYPE,equationsMatrices,err,error,*999)
            ENDIF
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime6,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime6,err,error,*999)
              userElapsed=userTime6(1)-userTime1(1)
              systemElapsed=systemTime6(1)-systemTime1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",systemElapsed, &
                & err,error,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",err,error,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",err,error,*999)
      ENDIF            
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    ENDIF
       
    EXITS("EquationsSet_JacobianEvaluateStaticNodal")
    RETURN
999 ERRORSEXITS("EquationsSet_JacobianEvaluateStaticNodal",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_JacobianEvaluateStaticNodal

  !
  !================================================================================================================================
  !

  !>Evaluates the residual for an static equations set using the nodal method
  SUBROUTINE EquationsSet_ResidualEvaluateStaticNodal(equationsSet,err,error,*)

    !Argument variables
    TYPE(EQUATIONS_SET_TYPE), POINTER :: equationsSet !<A pointer to the equations set to evaluate the residual for
    INTEGER(INTG), INTENT(OUT) :: err !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: error !<The error string
    !Local Variables
    INTEGER(INTG) :: numberOfTimes
    INTEGER(INTG) :: nodeIdx,nodeNumber
    REAL(SP) :: nodeUserElapsed,nodeSystemElapsed,userElapsed,userTime1(1),userTime2(1),userTime3(1),userTime4(1), &
      & userTime5(1),userTime6(1),systemElapsed,systemTime1(1),systemTime2(1),systemTime3(1),systemTime4(1), &
      & systemTime5(1),systemTime6(1)
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: nodalMapping
    TYPE(EQUATIONS_TYPE), POINTER :: equations
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: equationsMatrices
    TYPE(FIELD_TYPE), POINTER :: dependentField,geometricField
 
    ENTERS("EquationsSet_ResidualEvaluateStaticNodal",err,error,*999)

    IF(ASSOCIATED(equationsSet)) THEN
      dependentField=>equationsSet%DEPENDENT%DEPENDENT_FIELD
      geometricField=>equationsSet%GEOMETRY%GEOMETRIC_FIELD
      IF(ASSOCIATED(dependentField) .AND. ASSOCIATED(geometricField)) THEN
        equations=>equationsSet%EQUATIONS
        IF(ASSOCIATED(equations)) THEN
          equationsMatrices=>equations%EQUATIONS_MATRICES
          IF(ASSOCIATED(equationsMatrices)) THEN
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime1,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime1,err,error,*999)
            ENDIF
            !Initialise the matrices and rhs vector
            CALL EQUATIONS_MATRICES_VALUES_INITIALISE(equationsMatrices,EQUATIONS_MATRICES_NONLINEAR_ONLY,0.0_DP,err,error,*999)
            !Allocate the nodal matrices 
            CALL EquationsMatrices_NodalInitialise(equationsMatrices,err,error,*999)
            nodalMapping=>dependentField%DECOMPOSITION%DOMAIN(dependentField%DECOMPOSITION%MESH_COMPONENT_NUMBER)%PTR% &
              & MAPPINGS%NODES
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime2,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime2,err,error,*999)
              userElapsed=userTime2(1)-userTime1(1)
              systemElapsed=systemTime2(1)-systemTime1(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for equations setup and initialisation = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for equations setup and initialisation = ",systemElapsed, &
                & err,error,*999)
              nodeUserElapsed=0.0_SP
              nodeSystemElapsed=0.0_SP
            ENDIF
            numberOfTimes=0
            !Loop over the internal nodes
            DO nodeIdx=nodalMapping%INTERNAL_START,nodalMapping%INTERNAL_FINISH
              nodeNumber=nodalMapping%DOMAIN_LIST(nodeIdx)
              numberOfTimes=numberOfTimes+1
              CALL EquationsMatrices_NodalCalculate(equationsMatrices,nodeNumber,err,error,*999)
              CALL EquationsSet_NodalResidualEvaluate(equationsSet,nodeNumber,err,error,*999)
              CALL EquationsMatrices_NodeAdd(equationsMatrices,err,error,*999)
            ENDDO !nodeIdx
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime3,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime3,err,error,*999)
              userElapsed=userTime3(1)-userTime2(1)
              systemElapsed=systemTime3(1)-systemTime2(1)
              nodeUserElapsed=userElapsed
              nodeSystemElapsed=systemElapsed
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for internal equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for internal equations assembly = ",systemElapsed, &
                & err,error,*999)
            ENDIF
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime4,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime4,err,error,*999)
              userElapsed=userTime4(1)-userTime3(1)
              systemElapsed=systemTime4(1)-systemTime3(1)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for parameter transfer completion = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for parameter transfer completion = ",systemElapsed, &
                & err,error,*999)              
            ENDIF
            !Loop over the boundary and ghost nodes
            DO nodeIdx=nodalMapping%BOUNDARY_START,nodalMapping%GHOST_FINISH
              nodeNumber=nodalMapping%DOMAIN_LIST(nodeIdx)
              numberOfTimes=numberOfTimes+1
              CALL EquationsMatrices_NodalCalculate(equationsMatrices,nodeNumber,err,error,*999)
              CALL EquationsSet_NodalResidualEvaluate(equationsSet,nodeNumber,err,error,*999)
              CALL EquationsMatrices_NodeAdd(equationsMatrices,err,error,*999)
            ENDDO !nodeIdx
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime5,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime5,err,error,*999)
              userElapsed=userTime5(1)-userTime4(1)
              systemElapsed=systemTime5(1)-systemTime4(1)
              nodeUserElapsed=nodeUserElapsed+userElapsed
              nodeSystemElapsed=nodeSystemElapsed+userElapsed
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"User time for boundary+ghost equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"System time for boundary+ghost equations assembly = ",systemElapsed, &
                & err,error,*999)
              IF(numberOfTimes>0) THEN
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average node user time for equations assembly = ", &
                  & nodeUserElapsed/numberOfTimes,err,error,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Average node system time for equations assembly = ", &
                  & nodeSystemElapsed/numberOfTimes,err,error,*999)
              ENDIF
            ENDIF
            !Finalise the nodal matrices
            CALL EquationsMatrices_NodalFinalise(equationsMatrices,err,error,*999)
            !Output equations matrices and RHS vector if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_MATRIX_OUTPUT) THEN
              CALL EQUATIONS_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,equationsMatrices,err,error,*999)
            ENDIF
            !Output timing information if required
            IF(equations%OUTPUT_TYPE>=EQUATIONS_TIMING_OUTPUT) THEN
              CALL CPU_TIMER(USER_CPU,userTime6,err,error,*999)
              CALL CPU_TIMER(SYSTEM_CPU,systemTime6,err,error,*999)
              userElapsed=userTime6(1)-userTime1(1)
              systemElapsed=systemTime6(1)-systemTime1(1)
              CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for equations assembly = ",userElapsed, &
                & err,error,*999)
              CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total system time for equations assembly = ",systemElapsed, &
                & err,error,*999)
            ENDIF
          ELSE
            CALL FlagError("Equations matrices is not associated",err,error,*999)
          ENDIF
        ELSE
          CALL FlagError("Equations is not associated",err,error,*999)
        ENDIF
      ELSE
        CALL FlagError("Dependent field is not associated",err,error,*999)
      ENDIF
    ELSE
      CALL FlagError("Equations set is not associated.",err,error,*999)
    ENDIF
       
    EXITS("EquationsSet_ResidualEvaluateStaticNodal")
    RETURN
999 ERRORSEXITS("EquationsSet_ResidualEvaluateStaticNodal",err,error)
    RETURN 1
  END SUBROUTINE EquationsSet_ResidualEvaluateStaticNodal

  !
  !================================================================================================================================
  !

END MODULE EQUATIONS_SET_ROUTINES
