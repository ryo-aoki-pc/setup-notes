#!/usr/bin/env python3
"""docs/diagrams/*.diag を nwdiag / seqdiag で SVG にする。

方言は各ファイルの先頭（コメントを除く）のキーワード `nwdiag {` / `seqdiag {` で決める。
どちらも blockdiag 3.0.0 の上に載っていて、Pillow 10 で削除された API を呼ぶので、
そのままでは動かない。ここで 2 つだけ補ってから描画ツールを呼ぶ。

  - ImageFont.getsize()  … Pillow 10 で削除。getbbox() で代替する
  - Image.ANTIALIAS      … Pillow 10 で削除。LANCZOS に読み替える（PNG 出力時のみ使われる）

フォントは、Latin と日本語の両方の字形を持つものを指定する必要がある。
指定しないと blockdiag の自動検出は候補を見つけられず、豆腐になる。

生成後に背景の矩形を差し込む。blockdiag の SVG は背景が透明で線と文字が黒
なので、そのままでは GitHub のダークテーマで図が沈んで見えなくなる。
nwdiag の --no-transparency は PNG 専用で SVG には効かない。
"""
import importlib
import os
import pathlib
import re
import sys

from PIL import Image, ImageFont

if not hasattr(ImageFont.FreeTypeFont, "getsize"):
    def _getsize(self, text, *args, **kwargs):
        left, top, right, bottom = self.getbbox(text, *args, **kwargs)
        return right, bottom

    ImageFont.FreeTypeFont.getsize = _getsize

if not hasattr(Image, "ANTIALIAS"):
    Image.ANTIALIAS = Image.LANCZOS

KINDS = ("nwdiag", "seqdiag")
DEFAULT_FONT = "/usr/share/fonts/google-noto-sans-cjk-vf-fonts/NotoSansCJK-VF.ttc"
DIAGRAM_DIR = pathlib.Path(__file__).resolve().parent.parent / "docs" / "diagrams"
BACKGROUND = '<rect x="0" y="0" width="100%" height="100%" fill="#ffffff" />'

# blockdiag は font-family="sans-serif" としか書かない。フォント fallback をしない
# レンダラ（cairosvg など）ではそれが Latin 専用フォントに解決され、日本語が
# 消えることがある。CJK を持つ family を先に並べておく。
FONT_FAMILY_FROM = 'font-family="sans-serif"'
FONT_FAMILY_TO = 'font-family="Noto Sans CJK JP,Noto Sans,sans-serif"'


def _text_extents(svg_text):
    """<text> の左右端を、x / textLength / text-anchor から求める。"""
    for m in re.finditer(r"<text\b[^>]*>", svg_text):
        tag = m.group(0)
        x = re.search(r'\bx="([\d.-]+)"', tag)
        length = re.search(r'\btextLength="([\d.-]+)"', tag)
        if not x or not length:
            continue
        x, length = float(x.group(1)), float(length.group(1))
        anchor = re.search(r'\btext-anchor="(\w+)"', tag)
        anchor = anchor.group(1) if anchor else "start"
        if anchor == "middle":
            yield x - length / 2, x + length / 2
        elif anchor == "end":
            yield x - length, x
        else:
            yield x, x + length


def fit_canvas(svg_text):
    """はみ出したラベルが切れないように viewBox の幅を広げる。

    blockdiag はノードの位置だけでキャンバス幅を決めるので、右端のノードに
    付く長いアドレス文字列が canvas の外に出ることがある（実測）。
    """
    m = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', svg_text)
    if not m:
        return svg_text
    width, height = float(m.group(1)), float(m.group(2))
    extents = list(_text_extents(svg_text))
    if not extents:
        return svg_text
    needed = max(right for _, right in extents)
    leftmost = min(left for left, _ in extents)
    if leftmost < 0:
        print(f"  WARN: 左に {abs(leftmost):.0f}px はみ出したテキストがあります", file=sys.stderr)
    if needed <= width:
        return svg_text
    new_width = int(needed) + 8  # 右に少し余白を残す
    return svg_text.replace(m.group(0), f'viewBox="0 0 {new_width} {int(height)}"', 1)


def diagram_kind(src):
    """先頭の（コメントでない）行の最初の語で方言を決める。"""
    for line in src.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith(("//", "#")):
            continue
        head = stripped.split("{", 1)[0].split()
        kind = head[0] if head else ""
        if kind not in KINDS:
            sys.exit(f"未対応の方言です: {kind!r} ({src})。先頭は {' / '.join(KINDS)} のどれか")
        return kind
    sys.exit(f"方言のキーワードが見つかりません: {src}")


def renderer(kind):
    """<kind>.command.main を返す。shim を当てた後に import する必要がある。"""
    try:
        return importlib.import_module(f"{kind}.command").main
    except ModuleNotFoundError:
        sys.exit(f"{kind} が入っていません: python3 -m pip install --user {' '.join(KINDS)}")


def postprocess(svg_path):
    """生成された SVG に、背景・フォント指定・キャンバス幅の調整を施す。"""
    text = svg_path.read_text(encoding="utf-8")
    text = text.replace(FONT_FAMILY_FROM, FONT_FAMILY_TO)
    text = fit_canvas(text)
    if BACKGROUND not in text:
        text, n = re.subn(r"(<svg\b[^>]*>)", r"\1\n  " + BACKGROUND, text, count=1)
        if n != 1:
            sys.exit(f"<svg> 開始タグが見つからず、背景を入れられません: {svg_path}")
    svg_path.write_text(text, encoding="utf-8")


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
        rc = renderer(diagram_kind(src))(argv)
        if rc:
            sys.exit(f"生成に失敗しました: {src}")
        postprocess(dst)
        print(f"{src.relative_to(DIAGRAM_DIR.parent.parent)} -> {dst.relative_to(DIAGRAM_DIR.parent.parent)}")


if __name__ == "__main__":
    main()
