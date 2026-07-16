def to_nfs4_acl_spec(entries):
    """List of ACL entry dicts -> nfs4_setfacl spec string.
    entry keys: type (A/D/U/L), flag (optional: fd, dg, etc.), principal, permissions
    """
    parts = []
    for e in entries:
        parts.append("{0}:{1}:{2}:{3}".format(
            e.get('type', 'A'),
            e.get('flag', ''),
            e['principal'],
            e['permissions'],
        ))
    return ','.join(parts)


def normalize_nfs4_acl(raw):
    """Raw nfs4_getfacl output -> comma-joined spec string for comparison."""
    lines = [l.strip() for l in raw.splitlines() if l.strip() and not l.strip().startswith('#')]
    return ','.join(lines)


class FilterModule(object):
    def filters(self):
        return {
            'to_nfs4_acl_spec': to_nfs4_acl_spec,
            'normalize_nfs4_acl': normalize_nfs4_acl,
        }