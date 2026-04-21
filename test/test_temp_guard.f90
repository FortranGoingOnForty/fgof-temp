program test_temp_guard
  use fgof_temp, only : &
    FGOF_TEMP_OK, &
    cleanup_guard, &
    clear_temp_guard, &
    clear_temp_options, &
    guard_entry_count, &
    make_temp_dir, &
    make_temp_file, &
    register_temp
  use fgof_temp_posix, only : path_exists_posix
  use fgof_temp_types, only : temp_guard, temp_options, temp_resource
  implicit none

  type(temp_guard) :: guard
  type(temp_options) :: options
  type(temp_resource) :: dir_resource
  type(temp_resource) :: file_resource
  type(temp_resource) :: keep_file
  logical :: success

  guard = clear_temp_guard()

  dir_resource = make_temp_dir()
  if (.not. dir_resource%created) error stop "guard test should create a temp directory"

  options = clear_temp_options()
  options%parent_dir = dir_resource%path
  file_resource = make_temp_file(options)
  if (.not. file_resource%created) error stop "guard test should create a nested temp file"

  call register_temp(guard, dir_resource)
  call register_temp(guard, file_resource)
  if (guard_entry_count(guard) /= 2) error stop "guard should track two resources"
  if (.not. guard%active) error stop "guard should become active after registrations"
  if (dir_resource%owned) error stop "register_temp should transfer directory ownership"
  if (file_resource%owned) error stop "register_temp should transfer file ownership"

  success = cleanup_guard(guard)
  if (.not. success) error stop "guard cleanup should succeed for nested resources"
  if (guard_entry_count(guard) /= 0) error stop "guard cleanup should clear tracked resources"
  if (guard%active) error stop "guard cleanup should leave the guard inactive"
  if (guard%last_error_code /= FGOF_TEMP_OK) error stop "guard cleanup should report ok on success"
  if (path_exists_posix(file_resource%path)) error stop "guard cleanup should remove nested files first"
  if (path_exists_posix(dir_resource%path)) error stop "guard cleanup should remove directories after nested files"

  success = cleanup_guard(guard)
  if (.not. success) error stop "repeat guard cleanup should be idempotent"

  options = clear_temp_options()
  options%cleanup_on_close = .false.
  keep_file = make_temp_file(options)
  if (.not. keep_file%created) error stop "guard release test should create a temp file"

  call register_temp(guard, keep_file)
  if (guard_entry_count(guard) /= 1) error stop "guard should track released temp resources too"

  success = cleanup_guard(guard)
  if (.not. success) error stop "guard cleanup should succeed for cleanup-disabled resources"
  if (guard_entry_count(guard) /= 0) error stop "guard should clear cleanup-disabled entries"
  if (.not. path_exists_posix(keep_file%path)) error stop "guard cleanup should not delete cleanup-disabled resources"

  call remove_file(keep_file%path)
contains

  subroutine remove_file(path)
    character(len=*), intent(in) :: path
    integer :: unit
    integer :: ios

    open(newunit=unit, file=path, status="old", access="stream", form="unformatted", action="readwrite", iostat=ios)
    if (ios /= 0) error stop "manual file removal should reopen the released temp file"
    close(unit, status="delete", iostat=ios)
    if (ios /= 0) error stop "manual file removal should succeed"
  end subroutine remove_file
end program test_temp_guard
