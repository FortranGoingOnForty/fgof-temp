program guard_cleanup_demo
  use fgof_temp, only : cleanup_guard, clear_temp_guard, clear_temp_options, guard_entry_count, make_temp_dir, &
                        make_temp_file, register_temp
  use fgof_temp_types, only : temp_guard, temp_options, temp_resource
  implicit none

  type(temp_guard) :: guard
  type(temp_options) :: options
  type(temp_resource) :: dir_resource
  type(temp_resource) :: file_resource

  guard = clear_temp_guard()
  dir_resource = make_temp_dir()

  options = clear_temp_options()
  options%parent_dir = dir_resource%path
  file_resource = make_temp_file(options)

  call register_temp(guard, dir_resource)
  call register_temp(guard, file_resource)

  if (.not. cleanup_guard(guard)) stop 1
  print *, "tracked=", guard_entry_count(guard)
end program guard_cleanup_demo
