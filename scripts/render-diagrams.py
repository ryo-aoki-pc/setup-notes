#!/usr/bin/env python3
"""docs/diagrams/*.diag を nwdiag で SVG にする。

nwdiag（blockdiag 3.0.0）は Pillow 10 で削除された API を呼ぶので、
そのままでは動かない。ここで 2 つだけ補ってから nwdiag を呼ぶ。

  - ImageFont.getsize()  … Pillow 10 で削除。getbbox() で代替する
  - Image.ANTIALIAS      … Pillow 10 で削除。LANCZOS に読み替える（PNG 出力時のみ使われる）

フォントは、Latin と日本語の両方の字形を持つものを指定する必要がある。
指定しないと blockdiag の自動検出は候補を見つけられず、豆腐になる。
"""
import os
import pathlib
import sys

from PIL import Image, ImageFont

if not hasattr(ImageFont.FreeTypeFont, "getsize"):
    def _getsize(self, text, *args, **kwargs):
        left, top, right, bottom = self.getbbox(text, *args, **kwargs)
        return right, bottom

    ImageFont.FreeTypeFont.getsize = _getsize

if not hasattr(Image, "ANTIALIAS"):
    Image.ANTIALIAS = Image.LANCZOS

from nwdiag.command import main as nwdiag_main  # noqa: E402  (shim を当ててから import する)

DEFAULT_FONT = "/usr/share/fonts/google-noto-sans-cjk-vf-fonts/NotoSansCJK-VF.ttc"
DIAGRAM_DIR = pathlib.Path(__file__).resolve().parent.parent / "docs" / "diagrams"


def main():
    font = os.environ.get("WG_DIAG_FONT", DEFAULT_FONT)
    if not pathlib.Path(font).exists():
        sys.exit(
            f"フォントが見つかりません: {font}\n"
            "Latin と日本語の両方を持つフォントが要ります。AlmaLinux なら\n"
            "  sudo dnf install google-noto-sans-cjk-vf-fonts\n"
            "別のフォントを使う場合は WG_DIAG_FONT で指定してください。"
        )

    sources = sorted(DIAGRAM_DIR.glob("*.diag"))
    if not sources:
        sys.exit(f"*.diag がありません: {DIAGRAM_DIR}")

    for src in sources:
        dst = src.with_suffix(".svg")
        argv = ["-f", font, "-T", "svg", "-o", str(dst), str(src)]
        rc = nwdiag_main(argv)
        if rc:
            sys.exit(f"生成に失敗しました: {src}")
        print(f"{src.relative_to(DIAGRAM_DIR.parent.parent)} -> {dst.relative_to(DIAGRAM_DIR.parent.parent)}")


if __name__ == "__main__":
    main()
