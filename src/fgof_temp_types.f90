module fgof_temp_types
  implicit none
  private

  integer, parameter, public :: FGOF_TEMP_OK = 0
  integer, parameter, public :: FGOF_TEMP_ERR_INVALID_OPTIONS = 10
  integer, parameter, public :: FGOF_TEMP_ERR_CREATE_FAILED = 20
  integer, parameter, public :: FGOF_TEMP_ERR_CLEANUP_FAILED = 30
  integer, parameter, public :: FGOF_TEMP_ERR_WRITE_FAILED = 40
  integer, parameter, public :: FGOF_TEMP_ERR_REPLACE_FAILED = 50
  integer, parameter, public :: FGOF_TEMP_ERR_INTERNAL = 99

  type, public :: temp_options
    logical :: directory = .false.
    logical :: cleanup_on_close = .true.
    character(len=:), allocatable :: prefix
    character(len=:), allocatable :: suffix
    character(len=:), allocatable :: parent_dir
  end type temp_options

  type, public :: temp_resource
    logical :: created = .false.
    logical :: directory = .false.
    logical :: owned = .false.
    logical :: cleanup_on_close = .true.
    integer :: error_code = FGOF_TEMP_OK
    character(len=:), allocatable :: path
    character(len=:), allocatable :: error_message
  end type temp_resource

  type, public :: write_result
    logical :: completed = .false.
    logical :: replaced = .false.
    integer :: error_code = FGOF_TEMP_OK
    character(len=:), allocatable :: path
    character(len=:), allocatable :: staging_path
    character(len=:), allocatable :: error_message
  end type write_result

end module fgof_temp_types
