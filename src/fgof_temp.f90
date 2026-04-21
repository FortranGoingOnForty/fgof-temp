module fgof_temp
  use fgof_temp_types, only : &
    FGOF_TEMP_ERR_INTERNAL, &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_OK, &
    temp_options, &
    temp_resource
  implicit none
  private

  public :: &
    FGOF_TEMP_ERR_INTERNAL, &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_OK, &
    clear_temp_options, &
    clear_temp_resource, &
    temp_backend_name, &
    temp_error_name, &
    temp_options, &
    temp_resource

contains

  function clear_temp_options() result(options)
    type(temp_options) :: options

    options%directory = .false.
    options%cleanup_on_close = .true.
  end function clear_temp_options

  function clear_temp_resource() result(resource)
    type(temp_resource) :: resource

    resource%created = .false.
    resource%directory = .false.
    resource%owned = .false.
    resource%error_code = FGOF_TEMP_OK
    resource%path = ""
    resource%error_message = ""
  end function clear_temp_resource

  function temp_backend_name() result(name)
    character(len=:), allocatable :: name

    name = "filesystem"
  end function temp_backend_name

  function temp_error_name(code) result(name)
    integer, intent(in) :: code
    character(len=:), allocatable :: name

    select case (code)
    case (FGOF_TEMP_OK)
      name = "ok"
    case (FGOF_TEMP_ERR_INVALID_OPTIONS)
      name = "invalid-options"
    case (FGOF_TEMP_ERR_INTERNAL)
      name = "internal"
    case default
      name = "unknown"
    end select
  end function temp_error_name

end module fgof_temp
