#include <linux/types.h>

#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <linux/bpf.h>
#include <linux/errno.h>

struct sockaddr {
  unsigned short sa_family;
  char sa_data[14];
};

struct sockaddr_in {
  unsigned short sin_family;
  unsigned short sin_port;
};

#define __bswap_16(x) ((unsigned short)(__builtin_bswap16(x)))

// Описываем структуру правила (значение в нашей карте)
struct port_rule {
  unsigned short blocked_port;
  // Сюда в будущем можно добавить: blocked_files, max_processes и т.д.
};

// Создаем eBPF Map типа "Хэш-таблица"
struct {
  __uint(type, BPF_MAP_TYPE_HASH);
  __uint(max_entries, 1024);       // Максимум 1024 контролируемых юзеров
  __type(key, unsigned int);       // Ключ: UID пользователя
  __type(value, struct port_rule); // Значение: Структура с правилами
} rules_map SEC(".maps");

SEC("lsm/socket_bind")
int BPF_PROG(restrict_bind, struct socket *sock, struct sockaddr *address,
             int addrlen) {
  unsigned long long uid_gid = bpf_get_current_uid_gid();
  unsigned int uid = uid_gid & 0xFFFFFFFF;

  // Ищем в карте правила для текущего UID
  struct port_rule *rule = bpf_map_lookup_elem(&rules_map, &uid);

  // Если для юзера есть правило, проверяем порт
  if (rule && address->sa_family == 2) {
    struct sockaddr_in *addr4 = (struct sockaddr_in *)address;
    unsigned short port = __bswap_16(addr4->sin_port);

    if (port == rule->blocked_port) {
      bpf_printk("bpfsentry: Blocked UID %d from binding to dynamic port %d\n",
                 uid, port);
      return -EPERM; // В доступе отказано
    }
  }

  return 0;
}

char _license[] SEC("license") = "GPL";
