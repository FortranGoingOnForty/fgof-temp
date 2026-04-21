#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static const char *fgof_temp_default_parent(void) {
    const char *tmpdir = getenv("TMPDIR");
    if (tmpdir != NULL && tmpdir[0] != '\0') {
        return tmpdir;
    }
    return "/tmp";
}

static int fgof_temp_build_template(
    char *buffer,
    size_t buffer_len,
    const char *parent,
    const char *prefix,
    const char *suffix,
    int include_suffix
) {
    const char *base;
    const char *name_prefix;
    const char *name_suffix;
    int needs_sep;
    int written;

    base = (parent != NULL && parent[0] != '\0') ? parent : fgof_temp_default_parent();
    name_prefix = (prefix != NULL && prefix[0] != '\0') ? prefix : "fgof-temp-";
    name_suffix = (suffix != NULL) ? suffix : "";
    needs_sep = (base[0] != '\0' && base[strlen(base) - 1] != '/');

    if (include_suffix) {
        written = snprintf(
            buffer,
            buffer_len,
            "%s%s%sXXXXXX%s",
            base,
            needs_sep ? "/" : "",
            name_prefix,
            name_suffix
        );
    } else {
        written = snprintf(
            buffer,
            buffer_len,
            "%s%s%sXXXXXX",
            base,
            needs_sep ? "/" : "",
            name_prefix
        );
    }

    if (written < 0 || (size_t)written >= buffer_len) {
        errno = ENAMETOOLONG;
        return 0;
    }

    return 1;
}

int fgof_temp_create_file(
    const char *parent,
    const char *prefix,
    const char *suffix,
    char *path,
    int path_len,
    int *sys_errno
) {
    char template_path[4096];
    int fd;
    size_t suffix_len = 0;

    if (!fgof_temp_build_template(template_path, sizeof template_path, parent, prefix, suffix, 1)) {
        *sys_errno = errno;
        return 0;
    }

    if (suffix != NULL) {
      suffix_len = strlen(suffix);
    }

    if (suffix_len > 0) {
        fd = mkstemps(template_path, (int)suffix_len);
    } else {
        fd = mkstemp(template_path);
    }

    if (fd < 0) {
        *sys_errno = errno;
        return 0;
    }

    if (close(fd) != 0) {
        *sys_errno = errno;
        unlink(template_path);
        return 0;
    }

    if ((int)strlen(template_path) + 1 > path_len) {
        unlink(template_path);
        *sys_errno = ENAMETOOLONG;
        return 0;
    }

    strcpy(path, template_path);
    *sys_errno = 0;
    return 1;
}

int fgof_temp_create_dir(
    const char *parent,
    const char *prefix,
    char *path,
    int path_len,
    int *sys_errno
) {
    char template_path[4096];

    if (!fgof_temp_build_template(template_path, sizeof template_path, parent, prefix, "", 0)) {
        *sys_errno = errno;
        return 0;
    }

    if (mkdtemp(template_path) == NULL) {
        *sys_errno = errno;
        return 0;
    }

    if ((int)strlen(template_path) + 1 > path_len) {
        rmdir(template_path);
        *sys_errno = ENAMETOOLONG;
        return 0;
    }

    strcpy(path, template_path);
    *sys_errno = 0;
    return 1;
}

int fgof_temp_remove_path(const char *path, int directory, int *sys_errno) {
    int rc;

    if (directory != 0) {
        rc = rmdir(path);
    } else {
        rc = unlink(path);
    }

    if (rc != 0) {
        *sys_errno = errno;
        return 0;
    }

    *sys_errno = 0;
    return 1;
}

int fgof_temp_path_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0 ? 1 : 0;
}

int fgof_temp_is_directory(const char *path) {
    struct stat st;
    if (stat(path, &st) != 0) {
        return 0;
    }
    return S_ISDIR(st.st_mode) ? 1 : 0;
}

int fgof_temp_rename_path(const char *source, const char *destination, int *sys_errno) {
    if (rename(source, destination) != 0) {
        *sys_errno = errno;
        return 0;
    }

    *sys_errno = 0;
    return 1;
}
