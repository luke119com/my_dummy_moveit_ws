import os
import sys

# 說明：
# 這個模組負責將同資料夾（dummy_cli_tool）內的 `fibre` 套件載入，
# 並在載入成功時，把 `find_any`、`find_all` 轉出供外部直接呼叫。
#
# 為了應付不同的執行環境（以套件方式匯入、直接執行、或系統已安裝 fibre），
# 我們依序嘗試三種匯入策略：
# 1) 相對匯入：from .. import fibre  （最乾淨、標準的套件情境）
# 2) 動態路徑：把父層（dummy_cli_tool）加入 sys.path 後 import fibre
# 3) 系統層：直接 import 已安裝在系統的 fibre
#
# 只有在成功取得 fibre 物件時，才會導出 find_any/find_all，避免屬性未定義錯誤。
fibre = None
try:
    # 方案 1：相對匯入同層級的 fibre
    # 範例路徑：dummy_controller.dummy_cli_tool.fibre
    from .. import fibre as _fibre  # type: ignore
    fibre = _fibre
except Exception:
    # 方案 2：處理沒有套件上下文的情況，手動把父層加入 sys.path 再匯入
    try:
        # 將父層（dummy_cli_tool 目錄）加入 sys.path，使得 `import fibre` 能找到同包的 fibre
        _this_dir = os.path.dirname(os.path.abspath(__file__))
        _parent_dir = os.path.dirname(_this_dir)
        if _parent_dir not in sys.path:
            sys.path.insert(0, _parent_dir)
        import fibre as _fibre  # type: ignore
        fibre = _fibre
    except Exception:
        # 方案 3：最後手段，嘗試系統層已安裝的 fibre（若環境本身已提供）
        try:
            import fibre as _fibre  # type: ignore
            fibre = _fibre
        except Exception:
            fibre = None

# 若成功載入 fibre，則轉出常用的查找函式供外部直接使用
if fibre is not None:
    find_any = fibre.find_any
    find_all = fibre.find_all

# 延續原有慣例：提供 __version__ 字串（由 version 模組產生）
from .version import get_version_str

del get_version_str
