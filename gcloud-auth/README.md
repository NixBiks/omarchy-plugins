# gcloud-auth

Bar widget that shows the time left on the gcloud sign-in.

The Workspace has Google Cloud session control on. The gcloud account credential
and ADC stop refreshing a fixed time after sign-in, however much you use them. The
widget counts down to that time, so you can sign in again at a convenient moment
instead of in the middle of a script.

All data comes from `gcloud-auth-watch probe` in the dotfiles repo
(`scripts/.local/bin/gcloud-auth-watch`). The probe reads files and never calls
gcloud:

- The result of the last check, which the `gcloud-auth-watch.timer` systemd user
  timer writes every five minutes.
- The start of the current session: the first sign-in after a check saw the
  credentials expire.

A sign-in while the credentials still work does not move the end of the session.
On 2026-10-03, a sign-in at 10:41 left the end at 18:58, which was 24 hours after
the sign-in that followed the previous expiry. For this reason, the widget does not
start the countdown again at every sign-in.

The end time is an estimate: session start plus `sessionHours` (default 24). Google
does not tell the client when the session ends, so set `sessionHours` to the
Workspace admin policy (Admin console > Security > Access and data control > Google
Cloud session control). A failed check always overrides the countdown.

Click to sign in (`gcloud-auth-watch login`, the same terminal that the expiry
toast opens). Right-click to check now.

The bar is drawn in the bar's text color. The fill shrinks as the session runs
out: it is full right after the session starts and empty when a check fails. The
bar is dim when the session start or the check result is not known yet. Hover
shows the time left, the start and end, and when the last check ran.
