module fgof_temp
  use fgof_temp_posix, only : &
    create_temp_dir_posix, &
    create_temp_file_posix, &
    path_exists_posix, &
    rename_path_posix, &
    remove_temp_path_posix
  use fgof_temp_types, only : &
    FGOF_TEMP_ERR_CLEANUP_FAILED, &
    FGOF_TEMP_ERR_CREATE_FAILED, &
    FGOF_TEMP_ERR_INTERNAL, &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_ERR_REPLACE_FAILED, &
    FGOF_TEMP_ERR_WRITE_FAILED, &
    FGOF_TEMP_OK, &
    temp_guard_entry, &
    temp_guard, &
    temp_options, &
    temp_resource, &
    write_result
  implicit none
  private

  public :: &
    FGOF_TEMP_ERR_CLEANUP_FAILED, &
    FGOF_TEMP_ERR_CREATE_FAILED, &
    FGOF_TEMP_ERR_INTERNAL, &
    FGOF_TEMP_ERR_INVALID_OPTIONS, &
    FGOF_TEMP_ERR_REPLACE_FAILED, &
    FGOF_TEMP_ERR_WRITE_FAILED, &
    FGOF_TEMP_OK, &
    atomic_write, &
    clear_temp_guard, &
    clear_temp_options, &
    clear_temp_resource, &
    clear_write_result, &
    cleanup_guard, &
    cleanup_temp, &
    close_temp, &
    guard_entry_count, &
    make_temp_dir, &
    make_temp_file, &
    register_temp, &
    release_temp, &
    replace_file, &
    temp_backend_name, &
    temp_error_name, &
    temp_guard, &
    temp_options, &
    temp_resource, &
    write_result

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

  function clear_write_result() result(result_value)
    type(write_result) :: result_value

    result_value%completed = .false.
    result_value%replaced = .false.
    result_value%error_code = FGOF_TEMP_OK
    result_value%path = ""
    result_value%staging_path = ""
    result_value%error_message = ""
  end function clear_write_result

  function clear_temp_guard() result(guard)
    type(temp_guard) :: guard

    guard%active = .false.
    guard%tracked_count = 0
    guard%last_error_code = FGOF_TEMP_OK
    guard%last_error_message = ""
    allocate(guard%entries(0))
  end function clear_temp_guard

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

    if (.not. path_exists_posix(resource%path)) then
      resource%created = .false.
      resource%owned = .false.
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

  subroutine release_temp(resource)
    type(temp_resource), intent(inout) :: resource

    resource%owned = .false.
    resource%error_code = FGOF_TEMP_OK
    resource%error_message = ""
  end subroutine release_temp

  subroutine close_temp(resource)
    type(temp_resource), intent(inout) :: resource

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

    if (resource%cleanup_on_close) then
      call cleanup_temp(resource)
    else
      call release_temp(resource)
    end if
  end subroutine close_temp

  subroutine register_temp(guard, resource)
    type(temp_guard), intent(inout) :: guard
    type(temp_resource), intent(inout) :: resource
    integer :: next_index

    call clear_guard_error(guard)

    if (.not. resource%created) return
    if (.not. resource%owned) return

    next_index = guard%tracked_count + 1
    call ensure_guard_capacity(guard, next_index)

    guard%entries(next_index)%active = .true.
    guard%entries(next_index)%directory = resource%directory
    guard%entries(next_index)%cleanup_on_close = resource%cleanup_on_close
    guard%entries(next_index)%path = resource%path
    guard%tracked_count = next_index
    guard%active = (guard%tracked_count > 0)

    call release_temp(resource)
  end subroutine register_temp

  logical function cleanup_guard(guard) result(success)
    type(temp_guard), intent(inout) :: guard
    integer :: i
    integer :: sys_errno
    logical :: removed

    success = .true.
    call clear_guard_error(guard)

    if (.not. allocated(guard%entries)) then
      guard%active = .false.
      guard%tracked_count = 0
      return
    end if

    do i = size(guard%entries), 1, -1
      if (.not. guard%entries(i)%active) cycle

      if (guard%entries(i)%cleanup_on_close) then
        if (path_exists_posix(guard%entries(i)%path)) then
          removed = remove_temp_path_posix(guard%entries(i)%path, guard%entries(i)%directory, sys_errno)
          if (.not. removed) then
            success = .false.
            if (guard%last_error_code == FGOF_TEMP_OK) then
              guard%last_error_code = FGOF_TEMP_ERR_CLEANUP_FAILED
              guard%last_error_message = errno_message("guard cleanup failed", sys_errno)
            end if
            cycle
          end if
        end if
      end if

      guard%entries(i)%active = .false.
      if (allocated(guard%entries(i)%path)) deallocate(guard%entries(i)%path)
    end do

    guard%tracked_count = count_active_entries(guard)
    guard%active = (guard%tracked_count > 0)
  end function cleanup_guard

  integer function guard_entry_count(guard) result(count_value)
    type(temp_guard), intent(in) :: guard

    count_value = guard%tracked_count
  end function guard_entry_count

  function atomic_write(path, text) result(result_value)
    character(len=*), intent(in) :: path
    character(len=*), intent(in) :: text
    type(write_result) :: result_value
    type(temp_options) :: options
    type(temp_resource) :: staging
    integer :: sys_errno
    logical :: success

    result_value = clear_write_result()
    result_value%path = path

    if (.not. validate_target_path(path, result_value)) return

    options = clear_temp_options()
    options%parent_dir = parent_directory(path)
    options%prefix = ".fgof-temp-"

    staging = make_temp_file(options)
    if (.not. staging%created) then
      call set_write_error(result_value, staging%error_code, staging%error_message)
      return
    end if

    result_value%staging_path = staging%path

    success = write_text_file(staging%path, text, sys_errno)
    if (.not. success) then
      call cleanup_temp(staging)
      call set_write_error(result_value, FGOF_TEMP_ERR_WRITE_FAILED, errno_message("atomic write failed", sys_errno))
      return
    end if

    success = rename_path_posix(staging%path, path, sys_errno)
    if (.not. success) then
      call cleanup_temp(staging)
      call set_write_error(result_value, FGOF_TEMP_ERR_REPLACE_FAILED, errno_message("atomic replace failed", sys_errno))
      return
    end if

    staging%created = .false.
    staging%owned = .false.

    result_value%completed = .true.
    result_value%replaced = .true.
    result_value%error_code = FGOF_TEMP_OK
    result_value%error_message = ""
  end function atomic_write

  function replace_file(source, destination) result(result_value)
    character(len=*), intent(in) :: source
    character(len=*), intent(in) :: destination
    type(write_result) :: result_value
    integer :: sys_errno
    logical :: success

    result_value = clear_write_result()
    result_value%path = destination
    result_value%staging_path = source

    if (len(source) == 0) then
      call set_write_error(result_value, FGOF_TEMP_ERR_INVALID_OPTIONS, "source path must not be empty")
      return
    end if

    if (.not. validate_target_path(destination, result_value)) return

    if (.not. path_exists_posix(source)) then
      call set_write_error(result_value, FGOF_TEMP_ERR_INVALID_OPTIONS, "source path must exist")
      return
    end if

    success = rename_path_posix(source, destination, sys_errno)
    if (.not. success) then
      call set_write_error(result_value, FGOF_TEMP_ERR_REPLACE_FAILED, errno_message("replace failed", sys_errno))
      return
    end if

    result_value%completed = .true.
    result_value%replaced = .true.
    result_value%error_code = FGOF_TEMP_OK
    result_value%error_message = ""
  end function replace_file

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
    case (FGOF_TEMP_ERR_WRITE_FAILED)
      name = "write-failed"
    case (FGOF_TEMP_ERR_REPLACE_FAILED)
      name = "replace-failed"
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

  subroutine set_write_error(result_value, code, message)
    type(write_result), intent(inout) :: result_value
    integer, intent(in) :: code
    character(len=*), intent(in) :: message

    result_value%completed = .false.
    result_value%replaced = .false.
    result_value%error_code = code
    result_value%error_message = message
  end subroutine set_write_error

  subroutine clear_guard_error(guard)
    type(temp_guard), intent(inout) :: guard

    guard%last_error_code = FGOF_TEMP_OK
    guard%last_error_message = ""
  end subroutine clear_guard_error

  subroutine ensure_guard_capacity(guard, required_size)
    type(temp_guard), intent(inout) :: guard
    integer, intent(in) :: required_size
    type(temp_guard) :: fresh_guard
    integer :: old_size
    integer :: i

    if (.not. allocated(guard%entries)) then
      fresh_guard = clear_temp_guard()
      call move_alloc(fresh_guard%entries, guard%entries)
    end if

    old_size = size(guard%entries)
    if (old_size >= required_size) return

    block
      type(temp_guard_entry), allocatable :: resized(:)

      allocate(resized(required_size))
      if (old_size > 0) resized(:old_size) = guard%entries
      do i = old_size + 1, required_size
        resized(i)%active = .false.
        resized(i)%directory = .false.
        resized(i)%cleanup_on_close = .true.
        resized(i)%path = ""
      end do
      call move_alloc(resized, guard%entries)
    end block
  end subroutine ensure_guard_capacity

  integer function count_active_entries(guard) result(active_count)
    type(temp_guard), intent(in) :: guard
    integer :: i

    active_count = 0
    if (.not. allocated(guard%entries)) return

    do i = 1, size(guard%entries)
      if (guard%entries(i)%active) active_count = active_count + 1
    end do
  end function count_active_entries

  logical function validate_target_path(path, result_value) result(valid)
    character(len=*), intent(in) :: path
    type(write_result), intent(inout) :: result_value

    valid = .false.

    if (len(path) == 0) then
      call set_write_error(result_value, FGOF_TEMP_ERR_INVALID_OPTIONS, "target path must not be empty")
      return
    end if

    if (path(len(path):len(path)) == "/") then
      call set_write_error(result_value, FGOF_TEMP_ERR_INVALID_OPTIONS, "target path must name a file")
      return
    end if

    valid = .true.
  end function validate_target_path

  function parent_directory(path) result(parent)
    character(len=*), intent(in) :: path
    character(len=:), allocatable :: parent
    integer :: i
    integer :: slash_index

    slash_index = 0
    do i = len(path), 1, -1
      if (path(i:i) == "/") then
        slash_index = i
        exit
      end if
    end do

    if (slash_index == 0) then
      parent = "."
    else if (slash_index == 1) then
      parent = "/"
    else
      parent = path(:slash_index - 1)
    end if
  end function parent_directory

  logical function write_text_file(path, text, sys_errno) result(success)
    character(len=*), intent(in) :: path
    character(len=*), intent(in) :: text
    integer, intent(out) :: sys_errno
    integer :: unit
    integer :: ios

    open(newunit=unit, file=path, status="old", access="stream", form="unformatted", action="write", iostat=ios)
    if (ios /= 0) then
      sys_errno = ios
      success = .false.
      return
    end if

    if (len(text) > 0) then
      write(unit, iostat=ios) text
      if (ios /= 0) then
        close(unit)
        sys_errno = ios
        success = .false.
        return
      end if
    end if

    close(unit, iostat=ios)
    if (ios /= 0) then
      sys_errno = ios
      success = .false.
      return
    end if

    sys_errno = 0
    success = .true.
  end function write_text_file

  function errno_message(prefix, sys_errno) result(message)
    character(len=*), intent(in) :: prefix
    integer, intent(in) :: sys_errno
    character(len=:), allocatable :: message
    character(len=32) :: errno_text

    write(errno_text, "(i0)") sys_errno
    message = prefix // " (errno=" // trim(errno_text) // ")"
  end function errno_message

end module fgof_temp
