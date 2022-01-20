# macOS OpenVPN Setup

Set up a VPN using the OpenVPN client on macOS.

Based on https://github.com/bitrise-steplib/bitrise-step-open-vpn, with an additional call to `scutil` and `dscacheutil`. Also, stop using compression option so to enable compatibility with AWS Client VPN.

**WARNING:** Made for internal Cookpad use. Do not use it directly from your Bitrise workflow, it could break at anytime. We do not accept issues or pull requests from outside contributors. But feel free to have a look or fork.

**注意：** クックパッド社内用です。自分のBitrise workflowで参照しないでください。外部の方からのissueやpull requestを受け付けませんが、コードはご自由に読んでも良いですし、フォークしても構いません。
