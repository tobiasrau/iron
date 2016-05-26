!> \file
!> \author Richard Christie
!> \brief Framework for test logging.
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
!> The Original Code is OpenCMISS-Iron Simple Test Framework:
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand. Portions created by the University of Auckland are
!> Copyright (C) 2016 by the University of Auckland. All Rights Reserved.
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

MODULE IRON_TEST_FRAMEWORK

  USE KINDS
  USE OpenCMISS
  USE, INTRINSIC :: ISO_FORTRAN_ENV, only : output_unit, error_unit

  IMPLICIT NONE

  PRIVATE

  INTERFACE EXPECT_EQ
    MODULE PROCEDURE EXPECT_EQ_INTG
  END INTERFACE EXPECT_EQ

  INTERFACE EXPECT_NEAR
    MODULE PROCEDURE EXPECT_NEAR_DP
    MODULE PROCEDURE EXPECT_NEAR_SP
  END INTERFACE EXPECT_NEAR

  CHARACTER(LEN=:), ALLOCATABLE, SAVE :: current_test_name !< The name of the current test.
  INTEGER(CMISSIntg), SAVE :: test_err = 0

  PUBLIC INITIALISE_TESTS, FINALISE_TESTS, BEGIN_TEST, END_TEST, &
    & AUTO_USER_NUMBER, EXPECT_EQ, EXPECT_NEAR

CONTAINS

  !> Initialise contents of test framework. Must be done before first use.
  SUBROUTINE INITIALISE_TESTS()
    current_test_name = ""
    test_err = 0
  END SUBROUTINE INITIALISE_TESTS

  !> Clean up anything used in test framework and return result. Call after last test.
  SUBROUTINE FINALISE_TESTS(err)
    INTEGER(CMISSIntg), INTENT(OUT) :: err !< The test result, non-zero if failed.
    err = test_err
  END SUBROUTINE FINALISE_TESTS

  !> Begin test of the given name. Currently doesn't handle nested tests. Must pair with END_TEST
  SUBROUTINE BEGIN_TEST(test_name)
    CHARACTER(LEN=*), INTENT(IN) :: test_name !< The name of the test.

    IF (LEN(current_test_name) > 0) THEN
      WRITE(unit = error_unit, fmt = '("Called BEGIN_TEST when test in progress. Cannot nest tests. Aborting.")') 
      STOP 1
    ENDIF
    WRITE(unit = output_unit, fmt = '("----------------------------------------")')
    WRITE(unit = output_unit, fmt = '("Begin test: ",a)') test_name
    current_test_name = test_name
  END SUBROUTINE BEGIN_TEST

  !> End the current test. Test name is retained from prior call to BEGIN_TEST.
  SUBROUTINE END_TEST()
    IF (LEN(current_test_name) == 0) THEN
      WRITE(unit = error_unit, fmt = '("Called END_TEST without call to BEGIN_TEST. Aborting.")')
      STOP 1
    ENDIF
    WRITE(unit = output_unit, fmt = '("End test: ",a)') current_test_name
    current_test_name = ""
  END SUBROUTINE END_TEST

  !> Record that an error has occurred.
  SUBROUTINE set_err()
    test_err = 1
  END SUBROUTINE

  !> Generate a unique user number for an object, by incrementing an integer module variable.
  FUNCTION AUTO_USER_NUMBER() RESULT(user_number)
    INTEGER(CMISSIntg) :: user_number
    ! static variables
    INTEGER(CMISSIntg), SAVE :: next_user_number = 1

    user_number = next_user_number
    next_user_number = next_user_number + 1
  END FUNCTION AUTO_USER_NUMBER

  !> Check actual value is equal to expect, integer variant. Reports and records any error and continues.
  SUBROUTINE EXPECT_EQ_INTG(description, expected, actual)
    CHARACTER(LEN=*), INTENT(IN) :: description !< Description of quantity being compared.
    INTEGER(CMISSIntg), INTENT(IN) :: expected !< Expected value.
    INTEGER(CMISSIntg), INTENT(IN) :: actual !< Actual value.

    IF (actual /= expected) THEN
      WRITE(unit = output_unit, fmt = '("The value of ",a," (",i0,") is not near expected (",i0,")")') &
        & description, actual, expected
      CALL set_err()
    ENDIF
  END SUBROUTINE EXPECT_EQ_INTG

  !> Check actual value is within tolerance of expected. Reports and records any error and continues.
  SUBROUTINE EXPECT_NEAR_DP(description, expected, actual, tolerance)
    CHARACTER(LEN=*), INTENT(IN) :: description !< Description of quantity being compared.
    REAL(CMISSDP), INTENT(IN) :: expected !< Expected value.
    REAL(CMISSDP), INTENT(IN) :: actual !< Actual value.
    REAL(CMISSDP), INTENT(IN) :: tolerance !< Absolute tolerance actual value must be around expected value

    IF ((actual < (expected - tolerance)).OR.(actual > (expected + tolerance))) THEN
      WRITE(unit = output_unit, fmt = '("The value of ",a," (",g0,") is not near expected (",g0,") with tolerance (",g0,")")') &
        & description, actual, expected, tolerance
      CALL set_err()
    ENDIF
  END SUBROUTINE EXPECT_NEAR_DP

  !> Check actual value is within tolerance of expected. Reports and records any error and continues.
  SUBROUTINE EXPECT_NEAR_SP(description, expected, actual, tolerance)
    CHARACTER(LEN=*), INTENT(IN) :: description !< Description of quantity being compared.
    REAL(CMISSSP), INTENT(IN) :: expected !< Expected value.
    REAL(CMISSSP), INTENT(IN) :: actual !< Actual value.
    REAL(CMISSSP), INTENT(IN) :: tolerance !< Absolute tolerance actual value must be around expected value

    IF ((actual < (expected - tolerance)).OR.(actual > (expected + tolerance))) THEN
      WRITE(unit = output_unit, fmt = '("The value of ",a," (",g0,") is not near expected (",g0,") with tolerance (",g0,")")') &
        & description, actual, expected, tolerance
      CALL set_err()
    ENDIF
  END SUBROUTINE EXPECT_NEAR_SP

END MODULE IRON_TEST_FRAMEWORK
