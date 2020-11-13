acl = "write"

key "consul-snapshot/lock" {
  policy = "write"
}

service "consul-snapshot" {
  policy = "write"
}

session_prefix "" {
  policy = "write"
}