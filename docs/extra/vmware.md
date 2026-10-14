# VMware Workstation Pro のインストールと VM の作成（Windows 11）のロールバックと注意点

[手順書](../windows-setup.md#vmware-workstation-pro-実施手順)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/vmware.md)・[参考資料](../reference/vmware.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す

## ロールバック

- VM は、本書の[VM を消す](../windows-setup.md#vmware-workstation-pro-vm-を消す)で消す
- **VMware Workstation Pro のアンインストールは、まだ検証していないので載せていない**（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/vmware.md)）

---

## 注意点

- **Windows のハイパーバイザー（Hyper-V、WSL 2 の仮想マシン プラットフォームなど）が動いている PC では、VM はその上で動く**
  - VM のログ（`vmware.log`）に `Hyper-V detected by CPUID` と `Monitor Mode: ULM` が出る
  - Broadcom の文書は、このときゲストに CPU の仮想化支援が見えない（VM の中で別の VM を動かせない）としている（本書では確かめていない）
- **リンククローンの VM では、`vmrun getGuestIPAddress` が失敗した**
  - AlmaLinux 10.2（`open-vm-tools` 13.0.10）のリンククローンで、`Error: The VMware Tools are not running in the virtual machine` が返った。ゲストの中では `vmtoolsd` が動いていて、`vmrun checkToolsState` は `installed` だった
  - 同じ VM で、`vmrun readVariable <vmx> guestVar ip` は IP を返した。本書はこちらを使う
  - クローンの元の VM では、`getGuestIPAddress` も IP を返した
  - リンククローンでも、`vmrun stop <vmx> soft`（ゲストに電源を切らせる）は効いた
- **3D のアクセラレーションは切ってある**（[VM を作る](../windows-setup.md#vmware-workstation-pro-vm-を作る)の手順 3 の `MKS SetAccel3d false`）。25H2 のリリースノートに、有効だと RHEL 10 のインストールが灰色の画面で止まる、という既知の問題がある（本書では、有効にした場合を確かめていない）
- **`vmcli VM Create` の作る `.vmx` は、3D が有効で、ディスクも NIC もつながっていない**。[VM を作る](../windows-setup.md#vmware-workstation-pro-vm-を作る)の手順 3 を通すまで、起動しても OS は入らない
- **画面への入力で確かめたのは、文字と Enter だけ**。`vmcli MKS sendKeySequence` は文字列をそのまま打ち、文字列の中の改行が Enter になる。矢印・Esc・Tab・ファンクション キーを送る方法は確かめられていない
- **リンククローンのディスクは、元の VM のディスクを親として指す**（`.vmdk` の中の `parentFileNameHint` が、元の VM のフォルダーの `.vmdk` のパス）。元の VM を消したり動かしたりする前に、リンククローンを消す
