program test_cleanup_edges
  use fgof_temp, only : &
    FGOF_TEMP_ERR_CLEANUP_FAILED, &
    FGOF_TEMP_OK, &
    cleanup_guard, &
    cleanup_temp, &
    clear_temp_guard, &
    clear_temp_options, &
    guard_entry_count, &
    make_temp_dir, &
    make_temp_file, &
    register_temp, &
    release_temp
  use fgof_temp_posix, only : path_exists_posix
  use fgof_temp_types, only : temp_guard, temp_options, temp_resource
  implicit none

  type(temp_guard) :: guard
  type(temp_options) :: options
  type(temp_resource) :: file_resource
  type(temp_resource) :: dir_resource
  type(temp_resource) :: retained_dir
  type(temp_resource) :: removed_file
  type(temp_resource) :: replacement_file
  logical :: success
  character(len=:), allocatable :: child_path
  character(len=:), allocatable :: retained_child_path

  file_resource = make_temp_file()
  if (.not. file_resource%created) error stop "cleanup edge test should create a temp file"

  call remove_file(file_resource%path)
  call cleanup_temp(file_resource)
  if (file_resource%error_code /= FGOF_TEMP_OK) error stop "cleanup_temp should treat missing files as success"
  if (file_resource%created) error stop "cleanup_temp should clear created after missing-path cleanup"
  if (file_resource%owned) error stop "cleanup_temp should clear ownership after missing-path cleanup"

  options = clear_temp_options()
  options%cleanup_on_close = .true.
  file_resource = make_temp_file(options)
  if (.not. file_resource%created) error stop "release edge test should create a temp file"

  call release_temp(file_resource)
  call cleanup_temp(file_resource)
  if (file_resource%error_code /= FGOF_TEMP_OK) error stop "cleanup_temp should no-op cleanly on released resources"
  if (.not. path_exists_posix(file_resource%path)) error stop "cleanup_temp should not remove released files"
  call remove_file(file_resource%path)

  guard = clear_temp_guard()
  dir_resource = make_temp_dir()
  if (.not. dir_resource%created) error stop "guard cleanup edge test should create a temp directory"

  child_path = dir_resource%path // "/kept.txt"
  call write_text_file(child_path, "keep")

  call register_temp(guard, dir_resource)
  success = cleanup_guard(guard)
  if (success) error stop "cleanup_guard should fail on non-empty tracked directories"
  if (guard%last_error_code /= FGOF_TEMP_ERR_CLEANUP_FAILED) error stop "cleanup_guard should report cleanup failure"
  if (guard_entry_count(guard) /= 1) error stop "failed guard cleanup should keep the tracked entry active"
  if (.not. guard%active) error stop "failed guard cleanup should keep the guard active"
  if (.not. path_exists_posix(dir_resource%path)) error stop "failed guard cleanup should leave the directory in place"

  call remove_file(child_path)
  success = cleanup_guard(guard)
  if (.not. success) error stop "cleanup_guard should succeed on retry after the blocking child is removed"
  if (guard%last_error_code /= FGOF_TEMP_OK) error stop "successful guard retry should clear the prior error"
  if (guard_entry_count(guard) /= 0) error stop "successful guard retry should clear tracked entries"
  if (guard%active) error stop "successful guard retry should deactivate the guard"
  if (path_exists_posix(dir_resource%path)) error stop "successful guard retry should remove the directory"

  guard = clear_temp_guard()

  removed_file = make_temp_file()
  if (.not. removed_file%created) error stop "guard slot reuse test should create a temp file"

  retained_dir = make_temp_dir()
  if (.not. retained_dir%created) error stop "guard slot reuse test should create a temp directory"

  retained_child_path = retained_dir%path // "/blocked.txt"
  call write_text_file(retained_child_path, "keep")

  call register_temp(guard, removed_file)
  call register_temp(guard, retained_dir)

  success = cleanup_guard(guard)
  if (success) error stop "guard cleanup should fail when the higher slot stays blocked"
  if (guard_entry_count(guard) /= 1) error stop "guard cleanup should leave one active blocked entry"
  if (.not. path_exists_posix(retained_dir%path)) error stop "blocked guard entry should remain after failed cleanup"
  if (path_exists_posix(removed_file%path)) error stop "successful lower-slot cleanup should still remove its file"

  replacement_file = make_temp_file()
  if (.not. replacement_file%created) error stop "guard slot reuse test should create a replacement temp file"

  call register_temp(guard, replacement_file)
  if (guard_entry_count(guard) /= 2) error stop "register_temp should preserve blocked entries when reusing open guard slots"
  if (.not. path_exists_posix(replacement_file%path)) error stop "replacement guard entry should remain on disk until cleanup"

  call remove_file(retained_child_path)
  success = cleanup_guard(guard)
  if (.not. success) error stop "guard cleanup retry should succeed after the blocked entry is cleared"
  if (guard_entry_count(guard) /= 0) error stop "guard cleanup retry should remove both surviving entries"
  if (path_exists_posix(retained_dir%path)) error stop "guard cleanup retry should still remove the originally blocked directory"
  if (path_exists_posix(replacement_file%path)) error stop "guard cleanup retry should also remove the newly registered file"

contains

  subroutine remove_file(path)
    character(len=*), intent(in) :: path
    integer :: unit
    integer :: ios

    open(newunit=unit, file=path, status="old", access="stream", form="unformatted", action="readwrite", iostat=ios)
    if (ios /= 0) error stop "manual file removal should reopen the temp file"
    close(unit, status="delete", iostat=ios)
    if (ios /= 0) error stop "manual file removal should succeed"
  end subroutine remove_file

  subroutine write_text_file(path, text)
    character(len=*), intent(in) :: path
    character(len=*), intent(in) :: text
    integer :: unit
    integer :: ios

    open(newunit=unit, file=path, status="replace", access="stream", form="unformatted", action="write", iostat=ios)
    if (ios /= 0) error stop "manual write helper should create the file"
    if (len(text) > 0) then
      write(unit, iostat=ios) text
      if (ios /= 0) error stop "manual write helper should write the payload"
    end if
    close(unit, iostat=ios)
    if (ios /= 0) error stop "manual write helper should close cleanly"
  end subroutine write_text_file
end program test_cleanup_edges
