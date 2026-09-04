### Post-install layer — freebsd-omarchy (Hyprland desktop for FreeBSD).
### https://github.com/klimb/freebsd-omarchy
###
### omarchy's bootstrap MUST run as the non-root user AFTER the system has
### network. We install a one-shot rc.d service that runs on first boot,
### clones the repo into ~admin, runs bootstrap/install.sh, then disables
### itself.

# We need git to clone, and the admin user must exist (main script guarantees).
env ASSUME_ALWAYS_YES=YES pkg install -y git || true

# Record the admin user so the rc.d script knows who to run as.
mkdir -p /var/db
printf '%s\n' "$TARGET_ADMIN_USER" > /var/db/omarchy-firstboot.user
chmod 0644 /var/db/omarchy-firstboot.user

# One-shot rc.d service.
cat > /etc/rc.d/omarchy_firstboot <<'__OMARCHY_RC_EOF__'
#!/bin/sh
# PROVIDE: omarchy_firstboot
# REQUIRE: NETWORKING sshd
# KEYWORD: nojail

. /etc/rc.subr

name="omarchy_firstboot"
rcvar="omarchy_firstboot_enable"
start_cmd="${name}_start"
stop_cmd=":"

omarchy_firstboot_start()
{
    _user=$(cat /var/db/omarchy-firstboot.user 2>/dev/null)
    if [ -z "$_user" ]; then
        logger -t omarchy "no admin user recorded, skipping"
        return 0
    fi

    _home=$(getent passwd "$_user" | awk -F: '{print $6}')
    if [ ! -d "$_home" ]; then
        logger -t omarchy "home dir $_home missing, skipping"
        return 0
    fi

    logger -t omarchy "starting freebsd-omarchy bootstrap as $_user"
    _log=/var/log/omarchy-firstboot.log
    : > "$_log"
    chmod 0640 "$_log"

    if su -l "$_user" -c '
        set -eu
        cd "$HOME"
        if [ ! -d freebsd-omarchy ]; then
            git clone https://github.com/klimb/freebsd-omarchy
        fi
        cd freebsd-omarchy
        git pull --ff-only || true
        sh bootstrap/install.sh
    ' >> "$_log" 2>&1
    then
        sysrc omarchy_firstboot_enable="NO" >/dev/null
        logger -t omarchy "bootstrap complete; run 'omg' after login"
    else
        logger -t omarchy "bootstrap FAILED — see $_log; will retry next boot"
    fi
}

load_rc_config $name
: ${omarchy_firstboot_enable:=NO}
run_rc_command "$1"
__OMARCHY_RC_EOF__
chmod 0555 /etc/rc.d/omarchy_firstboot

# Arm the one-shot for first boot.
sysrc omarchy_firstboot_enable="YES"
