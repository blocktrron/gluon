#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <json-c/json.h>
#include <iwinfo.h>
#include <net/if.h>
#include <glob.h>
#include <alloca.h>

#include <libgluonutil.h>

#define NETIF_PREFIX "/sys/class/net/"
#define VIRTIF_PREFIX "/sys/devices/virtual/net/"
#define LOWERGLOB_SUFFIX "/lower_*"

static void badrequest() {
  printf("Status: 400 Bad Request\n\n");
  exit(1);
}

// recurse down to the lowest layer-2 interface
static int interface_get_lowest(const char *ifname, char *hwifname);
static int interface_get_lowest(const char *ifname, char *hwifname) {
  glob_t globbuf;
  char *fnamebuf = alloca(1 + strlen(VIRTIF_PREFIX) + IF_NAMESIZE +
                          strlen(LOWERGLOB_SUFFIX));
  char *lowentry = NULL;


  sprintf(fnamebuf, "%s%s%s", VIRTIF_PREFIX, ifname, LOWERGLOB_SUFFIX);
  glob(fnamebuf, GLOB_NOSORT | GLOB_NOESCAPE, NULL, &globbuf);

  if (globbuf.gl_pathc == 1) {
    lowentry = alloca(1 + strlen(globbuf.gl_pathv[0]));
    strncpy(lowentry, globbuf.gl_pathv[0], 1 + strlen(globbuf.gl_pathv[0]));
  }

  globfree(&globbuf);

  if (!lowentry) {
    char *path = alloca(1 + strlen(NETIF_PREFIX) + strlen(ifname));
    sprintf(path, "%s%s", NETIF_PREFIX, ifname);

    if(access(path, F_OK) != 0)
      return false;

    strncpy(hwifname, ifname, IF_NAMESIZE - 1);
    return true;
  } else {
    char buf[PATH_MAX];
    ssize_t len;

    if ((len = readlink(lowentry, buf, sizeof(buf)-1)) != -1)
      buf[len] = '\0';
    else
      return false;

    if (strncmp(buf, "../", 3) == 0) {
      return interface_get_lowest(strrchr(buf, '/') + 1, hwifname);
    } else {
      return false;
    }
  }
}

int main(int argc, char *argv[]) {
  if (argc != 2)
    badrequest();

  const char *ifname = argv[1];
  char hwifname[IF_NAMESIZE] = "";

  if (strlen(ifname) >= IF_NAMESIZE)
    badrequest();

  if (strcspn(ifname, "/\\[]{}*?") != strlen(ifname))
    badrequest();

  if (!interface_get_lowest(ifname, hwifname))
    badrequest();

  printf("Content-type: text/event-stream\n\n");

  while (true) {
    struct json_object *obj;
    obj = gluonutil_get_stations(hwifname);
    if (!obj) {
      badrequest();
      continue;
    }
    printf("data: %s\n\n", json_object_to_json_string_ext(obj, JSON_C_TO_STRING_PLAIN));
    fflush(stdout);
    json_object_put(obj);
    usleep(150000);
  }

  return 0;
}
