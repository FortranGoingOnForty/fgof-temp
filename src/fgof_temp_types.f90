module fgof_temp_types
  implicit none
  private

  integer, parameter, public :: FGOF_TEMP_OK = 0
  integer, parameter, public :: FGOF_TEMP_ERR_INVALID_OPTIONS = 10
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
    integer :: error_code = FGOF_TEMP_OK
    character(len=:), allocatable :: path
    character(len=:), allocatable :: error_message
  end type temp_resource

end module fgof_temp_types
