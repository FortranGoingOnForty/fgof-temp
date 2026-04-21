module fgof_temp
  use fgof_temp_posix, only : &
    create_temp_dir_posix, &
    create_temp_file_posix, &
    remove_temp_path_posix
  use fgof_temp_types, only : &
    FGOF_TEMP_ERR_CLEANUP_FAILED, &
    FGOF_TEMP_ERR_CREATE_FAILED, &
    FGOF_TEMP_ERR_INTERNAL, &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_OK, &
    temp_options, &
    temp_resource
  implicit none
  private

  public :: &
    FGOF_TEMP_ERR_CLEANUP_FAILED, &
    FGOF_TEMP_ERR_CREATE_FAILED, &
    FGOF_TEMP_ERR_INTERNAL, &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_OK, &
    clear_temp_options, &
    clear_temp_resource, &
    cleanup_temp, &
    make_temp_dir, &
    make_temp_file, &
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
    resource%cleanup_on_close = .true.
    resource%error_code = FGOF_TEMP_OK
    resource%path = ""
    resource%error_message = ""
  end function clear_temp_resource

  function make_temp_file(options) result(resource)
    type(temp_options), intent(in), optional :: options
    type(temp_resource) :: resource
    type(temp_options) :: local_options
    character(len=:), allocatable :: path
    integer :: sys_errno
    logical :: success

    local_options = merged_options(options)
    resource = prepare_resource(.false., local_options)

    if (.not. validate_options(local_options, .false., resource)) return

    success = create_temp_file_posix(option_value(local_options%parent_dir), option_value(local_options%prefix), &
                                     option_value(local_options%suffix), path, sys_errno)
    if (.not. success) then
      call set_error(resource, FGOF_TEMP_ERR_CREATE_FAILED, errno_message("temp file creation failed", sys_errno))
      return
    end if

    resource%created = .true.
    resource%owned = .true.
    resource%path = path
    resource%error_code = FGOF_TEMP_OK
    resource%error_message = ""
  end function make_temp_file

  function make_temp_dir(options) result(resource)
    type(temp_options), intent(in), optional :: options
    type(temp_resource) :: resource
    type(temp_options) :: local_options
    character(len=:), allocatable :: path
    integer :: sys_errno
    logical :: success

    local_options = merged_options(options)
    resource = prepare_resource(.true., local_options)

    if (.not. validate_options(local_options, .true., resource)) return

    success = create_temp_dir_posix(option_value(local_options%parent_dir), option_value(local_options%prefix), path, sys_errno)
    if (.not. success) then
      call set_error(resource, FGOF_TEMP_ERR_CREATE_FAILED, errno_message("temp directory creation failed", sys_errno))
      return
    end if

    resource%created = .true.
    resource%owned = .true.
    resource%path = path
    resource%error_code = FGOF_TEMP_OK
    resource%error_message = ""
  end function make_temp_dir

  subroutine cleanup_temp(resource)
    type(temp_resource), intent(inout) :: resource
    integer :: sys_errno
    logical :: success

    if (.not. resource%created) then
      resource%error_code = FGOF_TEMP_OK
      resource%error_message = ""
      return
    end if

    if (.not. resource%owned) then
      resource%error_code = FGOF_TEMP_OK
      resource%error_message = ""
      return
    end if

    success = remove_temp_path_posix(resource%path, resource%directory, sys_errno)
    if (.not. success) then
      call set_error(resource, FGOF_TEMP_ERR_CLEANUP_FAILED, errno_message("temp cleanup failed", sys_errno))
      return
    end if

    resource%created = .false.
    resource%owned = .false.
    resource%error_code = FGOF_TEMP_OK
    resource%error_message = ""
  end subroutine cleanup_temp

  function temp_backend_name() result(name)
    character(len=:), allocatable :: name

    name = "posix"
  end function temp_backend_name

  function temp_error_name(code) result(name)
    integer, intent(in) :: code
    character(len=:), allocatable :: name

    select case (code)
    case (FGOF_TEMP_OK)
      name = "ok"
    case (FGOF_TEMP_ERR_INVALID_OPTIONS)
      name = "invalid-options"
    case (FGOF_TEMP_ERR_CREATE_FAILED)
      name = "create-failed"
    case (FGOF_TEMP_ERR_CLEANUP_FAILED)
      name = "cleanup-failed"
    case (FGOF_TEMP_ERR_INTERNAL)
      name = "internal"
    case default
      name = "unknown"
    end select
  end function temp_error_name

  function merged_options(options) result(local_options)
    type(temp_options), intent(in), optional :: options
    type(temp_options) :: local_options

    local_options = clear_temp_options()
    if (present(options)) local_options = options
  end function merged_options

  function prepare_resource(directory, options) result(resource)
    logical, intent(in) :: directory
    type(temp_options), intent(in) :: options
    type(temp_resource) :: resource

    resource = clear_temp_resource()
    resource%directory = directory
    resource%cleanup_on_close = options%cleanup_on_close
  end function prepare_resource

  logical function validate_options(options, directory, resource) result(valid)
    type(temp_options), intent(in) :: options
    logical, intent(in) :: directory
    type(temp_resource), intent(inout) :: resource

    valid = .false.

    if (allocated(options%prefix)) then
      if (index(options%prefix, "/") > 0) then
        call set_error(resource, FGOF_TEMP_ERR_INVALID_OPTIONS, "prefix must not contain '/'")
        return
      end if
    end if

    if (allocated(options%suffix)) then
      if (index(options%suffix, "/") > 0) then
        call set_error(resource, FGOF_TEMP_ERR_INVALID_OPTIONS, "suffix must not contain '/'")
        return
      end if
      if (directory .and. len(options%suffix) > 0) then
        call set_error(resource, FGOF_TEMP_ERR_INVALID_OPTIONS, "directory temp paths do not support suffixes")
        return
      end if
    end if

    valid = .true.
  end function validate_options

  function option_value(value) result(text)
    character(len=:), allocatable, intent(in) :: value
    character(len=:), allocatable :: text

    if (allocated(value)) then
      text = value
    else
      text = ""
    end if
  end function option_value

  subroutine set_error(resource, code, message)
    type(temp_resource), intent(inout) :: resource
    integer, intent(in) :: code
    character(len=*), intent(in) :: message

    resource%error_code = code
    resource%error_message = message
  end subroutine set_error

  function errno_message(prefix, sys_errno) result(message)
    character(len=*), intent(in) :: prefix
    integer, intent(in) :: sys_errno
    character(len=:), allocatable :: message
    character(len=32) :: errno_text

    write(errno_text, "(i0)") sys_errno
    message = prefix // " (errno=" // trim(errno_text) // ")"
  end function errno_message

end module fgof_temp
