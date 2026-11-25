#!/usr/bin/env bash

# ==============================================================================
#  ARI-DEV INTERACTIVE GIT TUI (Soft Blue Edition + Bilingual EN/ID + Long Path)
# ==============================================================================

# --- Deteksi bahasa sebelum memaksa LC_ALL ke UTF-8 ---
RAW_LOCALE="${TUI_LANG:-${LC_MESSAGES:-${LANG:-en}}}"
case "${RAW_LOCALE,,}" in
  id*) TUI_LANG="id" ;;
  *)   TUI_LANG="en" ;;
esac

# --- Parsing argumen CLI opsional (--lang en|id) ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--lang)
      case "${2,,}" in
        id|en) TUI_LANG="${2,,}" ;;
        *)
          echo "Invalid language: '$2'. Supported: en, id"
          exit 1
          ;;
      esac
      shift 2
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--lang en|id]"
      echo "  --lang en   Run interface in English"
      echo "  --lang id   Jalankan antarmuka dalam Bahasa Indonesia"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# --- Paksa UTF-8 agar glyph Nerd Font tidak pecah ---
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"

# ==============================================================================
# 1. NERD FONT ICONS (100% BMP Safe - Kompatibel Nerd Font v2 & v3)
# ==============================================================================
IC_GIT=$'\ue725'        #  Git / Branch
IC_REPO=$'\uf07b'       #  Folder / Repo
IC_SYNC=$'\uf021'       #  Refresh / Status
IC_OK=$'\uf058'         #  Success / Clean
IC_WARN=$'\uf071'       #  Warning
IC_ERR=$'\uf057'        #  Error / Danger
IC_SEARCH=$'\uf002'     #  Search
IC_REMOTE=$'\uf0ac'     #  Remote / Globe
IC_FETCH=$'\uf0ed'      #  Cloud Download / Fetch
IC_PULL=$'\uf063'       #  Arrow Down / Pull
IC_PUSH=$'\uf062'       #  Arrow Up / Push
IC_TAG=$'\uf02b'        #  Tag
IC_HIST=$'\uf1da'       #  History
IC_ADD=$'\uf067'        #  New / Add
IC_LINK=$'\uf0c1'       #  Link / Upstream
IC_STAGE=$'\uf187'      #  Box / Stage & Commit
IC_TRASH=$'\uf1f8'      #  Trash / Discard
IC_DIFF=$'\uf0db'       #  Columns / Visual Diff
IC_FIRE=$'\uf06d'       #  Fire / Bulk Delete / Force
IC_EXIT=$'\uf08b'       #  Exit
IC_FILE=$'\uf15b'       #  File
IC_EDIT=$'\uf040'       #  Edit / Rename
IC_LIST=$'\uf03a'       #  List
IC_BACK=$'\uf060'       #  Back
IC_CAL=$'\uf073'        #  Calendar
IC_USER=$'\uf007'       #  Author
IC_MERGE=$'\ue727'      #  Merge Commit
IC_COMMIT=$'\uf417'     #  Normal Commit
IC_PLUS=$'\uf055'       #  Insertions
IC_MINUS=$'\uf056'      #  Deletions
IC_TOOL=$'\uf0ad'       #  Tool / Resolve
IC_CHEV=$'\uf054'       #  Prompt Chevron
IC_LANG=$'\uf1ab'       #  Language / Translate

# ==============================================================================
# 2. LOCALIZATION ENGINE (ENGLISH & BAHASA INDONESIA)
# ==============================================================================
tr_text() {
  local en_str="$1"
  local id_str="$2"
  if [ "$TUI_LANG" = "id" ]; then
    printf '%s' "$id_str"
  else
    printf '%s' "$en_str"
  fi
}

toggle_language() {
  if [ "$TUI_LANG" = "id" ]; then
    TUI_LANG="en"
  else
    TUI_LANG="id"
  fi
}

# ==============================================================================
# 3. SOFT BLUE PALETTE (TrueColor ANSI & FZF Theme)
# ==============================================================================
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'

C_BLUE=$'\033[38;2;122;162;247m'     # #7AA2F7 - Primary Soft Blue
C_SKY=$'\033[38;2;125;207;255m'      # #7DCFFF - Sky / Ice Blue Accent
C_PERI=$'\033[38;2;180;190;254m'     # #B4BEFE - Periwinkle Soft
C_TEXT=$'\033[38;2;192;202;245m'     # #C0CAF5 - Soft White/Blue Text
C_MUTED=$'\033[38;2;86;95;137m'      # #565F89 - Slate Muted
C_BORDER=$'\033[38;2;61;89;161m'     # #3D59A1 - Deep Soft Blue Border
C_GREEN=$'\033[38;2;158;206;106m'    # #9ECE6A - Soft Sage Green
C_AMBER=$'\033[38;2;224;175;104m'    # #E0AF68 - Soft Amber Warning
C_RED=$'\033[38;2;247;118;142m'      # #F7768E - Soft Coral Red

# Tema global FZF bergaya Soft Blue (margin/padding ringkas agar ruang teks maksimal)
export FZF_DEFAULT_OPTS="
  --ansi
  --layout=reverse
  --border=rounded
  --border-label-pos=3
  --info=inline-right
  --margin=0,1
  --padding=1,1
  --prompt='${IC_CHEV}  '
  --pointer='▌'
  --marker='┃'
  --color=bg+:#242e42,fg:#c0caf5,fg+:#ffffff,hl:#7dcfff,hl+:#7aa2f7
  --color=info:#565f89,prompt:#7aa2f7,pointer:#7dcfff,marker:#9ece6a
  --color=spinner:#7dcfff,header:#7aa2f7,border:#3d59a1,label:#7dcfff
"

# Deteksi opsi FZF untuk long path secara kompatibel lintas versi
FZF_PATH_OPTS=()
FZF_HELP_OUT=$(fzf --help 2>/dev/null || true)
if grep -q -- '--wrap' <<<"$FZF_HELP_OUT"; then
  FZF_PATH_OPTS+=(--wrap)
elif grep -q -- '--keep-right' <<<"$FZF_HELP_OUT"; then
  FZF_PATH_OPTS+=(--keep-right)
fi
if grep -q -- '--ellipsis' <<<"$FZF_HELP_OUT"; then
  FZF_PATH_OPTS+=(--ellipsis='…')
fi

# Helper wrapper FZF standar
tui_fzf() {
  local label="$1"
  shift
  fzf --border-label=" ${IC_GIT}  ${label} " "$@"
}

# Helper wrapper FZF khusus daftar file/folder ber-path panjang (full width + preview bawah)
tui_fzf_path() {
  local label="$1"
  shift
  tui_fzf "$label" \
    --preview-window="down:55%:wrap" \
    "${FZF_PATH_OPTS[@]}" \
    "$@"
}

# Helper 2-kolom untuk hint shortcut agar rata & berjarak jelas
hint_2col() {
  local k1="$1" d1="$2" k2="$3" d2="$4"
  local left_plain="[$k1] $d1"
  local col_width=35
  local pad_len=$((col_width - ${#left_plain}))
  [ "$pad_len" -lt 4 ] && pad_len=4

  local spacer
  spacer=$(printf '%*s' "$pad_len" "")

  local out="${C_SKY}${C_BOLD}[${k1}]${C_RESET} ${C_TEXT}${d1}${C_RESET}${spacer}"
  if [ -n "$k2" ]; then
    out+="${C_SKY}${C_BOLD}[${k2}]${C_RESET} ${C_TEXT}${d2}${C_RESET}"
  fi
  printf '%b' "$out"
}

hint_divider() {
  printf '%b' "${C_BORDER}────────────────────────────────────────────────────────────────────────${C_RESET}"
}

# ==============================================================================
# 4. PRE-FLIGHT DEPENDENCY & NERD FONT VALIDATION
# ==============================================================================
check_dependencies() {
  local missing_pkgs=()

  command -v git >/dev/null 2>&1  || missing_pkgs+=("git")
  command -v fzf >/dev/null 2>&1  || missing_pkgs+=("fzf")
  command -v gawk >/dev/null 2>&1 || missing_pkgs+=("gawk")
  command -v meld >/dev/null 2>&1 || missing_pkgs+=("meld")

  if [ ${#missing_pkgs[@]} -gt 0 ]; then
    echo -e "${C_RED}${C_BOLD}${IC_ERR}  $(tr_text "Missing required dependencies:" "Dependency wajib belum terinstal:")${C_RESET} ${C_AMBER}${missing_pkgs[*]}${C_RESET}"
    echo -e "${C_TEXT}  $(tr_text "Run the following command to install:" "Jalankan perintah berikut untuk menginstal:")${C_RESET}"
    echo -e "${C_SKY}  sudo apt update && sudo apt install -y ${missing_pkgs[*]}${C_RESET}"
    exit 1
  fi

  # Cek Nerd Font via fontconfig (kecuali dilewati via SKIP_FONT_CHECK=1)
  if [ "${SKIP_FONT_CHECK:-0}" != "1" ] && command -v fc-list >/dev/null 2>&1; then
    if ! fc-list : family | grep -qiE "Nerd Font|NFM|NFP|NF"; then
      echo -e "${C_AMBER}${C_BOLD}${IC_WARN}  $(tr_text "Warning: Nerd Font not detected on local system." "Peringatan: Nerd Font tidak terdeteksi di sistem lokal.")${C_RESET}"
      echo -e "${C_TEXT}  $(tr_text "Ensure your terminal uses a Nerd Font (e.g., JetBrainsMono Nerd Font)" "Pastikan terminal Anda menggunakan Nerd Font (misal: JetBrainsMono Nerd Font)")${C_RESET}"
      echo -e "${C_TEXT}  $(tr_text "so all TUI icons render properly." "agar seluruh ikon TUI tampil sempurna.")${C_RESET}"
      echo -e "${C_MUTED}  $(tr_text "(Set SKIP_FONT_CHECK=1 if connecting via SSH from a Nerd Font terminal)" "(Set SKIP_FONT_CHECK=1 jika mengakses via SSH dari terminal ber-Nerd Font)")${C_RESET}"
      read -rp "  $(tr_text "Continue launching TUI anyway? [Y/n]: " "Lanjutkan tetap membuka TUI? [Y/n]: ")" font_ans
      [[ "$font_ans" =~ ^[Nn]$ ]] && exit 1
    fi
  fi
}

check_dependencies

# --- Validasi Git Repo ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo -e "${C_RED}${C_BOLD}${IC_ERR}  $(tr_text "Current directory is not a Git repository." "Direktori ini bukan Git repository.")${C_RESET}"
  exit 1
fi

# --- Cek Optional Tools ---
USE_DELTA=false
command -v delta >/dev/null 2>&1 && USE_DELTA=true

USE_KOMPARE=false
command -v kompare >/dev/null 2>&1 && USE_KOMPARE=true

# ==============================================================================
# 5. HELPER FUNCTIONS & HEADER RENDERER
# ==============================================================================
confirm() {
  local hint_yes
  hint_yes=$(tr_text "(type YES)" "(ketik YES)")
  echo -ne "\n  ${C_AMBER}${IC_WARN}  $1 ${C_BOLD}${hint_yes}${C_RESET}${C_SKY}: ${C_RESET}"
  read -r CONFIRM
  [[ "$CONFIRM" == "YES" ]]
}

pause_tui() {
  echo ""
  echo -ne "${C_MUTED}  ${IC_BACK}  $(tr_text "Press [ENTER] to continue..." "Tekan [ENTER] untuk melanjutkan...")${C_RESET}"
  read -r _
}

msg_ok()   { echo -e "\n  ${C_GREEN}${C_BOLD}${IC_OK}  $1${C_RESET}"; }
msg_warn() { echo -e "\n  ${C_AMBER}${C_BOLD}${IC_WARN}  $1${C_RESET}"; }
msg_err()  { echo -e "\n  ${C_RED}${C_BOLD}${IC_ERR}  $1${C_RESET}"; }
msg_info() { echo -e "\n  ${C_SKY}${IC_SYNC}  $1${C_RESET}"; }

is_dirty() {
  ! git diff --quiet || ! git diff --cached --quiet
}

extract_status_file() {
  sed -E 's/^.. //; s/^.* -> //; s/^"(.*)"$/\1/'
}

truncate_str() {
  local str="$1"
  local max_len="$2"
  if [ "$max_len" -gt 3 ] && [ "${#str}" -gt "$max_len" ]; then
    printf '%s…' "${str:0:$((max_len - 1))}"
  else
    printf '%s' "$str"
  fi
}

upstream_status() {
  local upstream ahead behind
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)
  if [ -z "$upstream" ]; then
    echo -e "${C_AMBER}${IC_WARN}  $(tr_text "No upstream" "Tanpa upstream")${C_RESET}"
    return
  fi

  read -r ahead behind <<< "$(git rev-list --left-right --count 'HEAD...@{upstream}')"

  if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
    echo -e "${C_RED}${IC_PULL}  ${behind}  ${C_MUTED}|${C_SKY}  ${IC_PUSH}  ${ahead} ${C_AMBER}$(tr_text "(DIVERGED)" "(BERCABANG)")${C_RESET}"
  elif [ "$behind" -gt 0 ]; then
    echo -e "${C_AMBER}${IC_PULL}  ${behind} $(tr_text "commit(s) behind (PULL)" "commit tertinggal (PULL)")${C_RESET}"
  elif [ "$ahead" -gt 0 ]; then
    echo -e "${C_SKY}${IC_PUSH}  ${ahead} $(tr_text "commit(s) ahead (PUSH)" "commit lebih maju (PUSH)")${C_RESET}"
  else
    echo -e "${C_GREEN}${IC_OK}  $(tr_text "Up to date" "Sudah sinkron")${C_RESET}"
  fi
}

git_author_status() {
  local eff_name eff_email loc_name loc_email scope_badge
  eff_name=$(git config user.name 2>/dev/null)
  eff_email=$(git config user.email 2>/dev/null)
  loc_name=$(git config --local user.name 2>/dev/null)
  loc_email=$(git config --local user.email 2>/dev/null)

  if [ -z "$eff_name" ] && [ -z "$eff_email" ]; then
    echo -e "${C_RED}${IC_WARN}  $(tr_text "Not set (Unset)" "Belum diatur (Unset)")${C_RESET}"
    return
  fi

  if [ -n "$loc_name" ] && [ -n "$loc_email" ]; then
    scope_badge="${C_SKY}[local]${C_RESET}"
  elif [ -n "$loc_name" ] || [ -n "$loc_email" ]; then
    scope_badge="${C_AMBER}[local+global]${C_RESET}"
  else
    scope_badge="${C_MUTED}[global]${C_RESET}"
  fi

  if [ -n "$eff_name" ] && [ -n "$eff_email" ]; then
    echo -e "${C_TEXT}${eff_name} ${C_MUTED}<${eff_email}>${C_RESET} ${scope_badge}"
  else
    local no_name no_email
    no_name=$(tr_text "(no name)" "(tanpa nama)")
    no_email=$(tr_text "no email" "tanpa email")
    echo -e "${C_AMBER}${eff_name:-"$no_name"} <${eff_email:-"$no_email"}>${C_RESET} ${scope_badge}"
  fi
}

set_git_author() {
  local scope_flag="$1"
  local scope_label="$2"

  local cur_name cur_email eff_name eff_email unset_txt
  cur_name=$(git config "$scope_flag" user.name 2>/dev/null)
  cur_email=$(git config "$scope_flag" user.email 2>/dev/null)
  eff_name=$(git config user.name 2>/dev/null)
  eff_email=$(git config user.email 2>/dev/null)
  unset_txt=$(tr_text "(not set)" "(belum di-set)")

  echo -e "\n  ${C_BLUE}${C_BOLD}${IC_USER}  $(tr_text "Git Author Configuration" "Konfigurasi Git Author") — ${C_SKY}${scope_label}${C_RESET}"
  echo -e "  ${C_BORDER}────────────────────────────────────────────────────────${C_RESET}"
  echo -e "  ${C_TEXT}$(tr_text "Name" "Nama") (${scope_flag#--})  : ${C_SKY}${cur_name:-"$unset_txt"}${C_RESET}"
  echo -e "  ${C_TEXT}Email (${scope_flag#--}) : ${C_SKY}${cur_email:-"$unset_txt"}${C_RESET}"
  if [ "$scope_flag" = "--local" ] && { [ -n "$eff_name" ] || [ -n "$eff_email" ]; }; then
    echo -e "  ${C_MUTED}$(tr_text "Currently active" "Aktif saat ini") : ${eff_name:-"-"} <${eff_email:-"-"}>${C_RESET}"
  fi
  echo -e "  ${C_BORDER}────────────────────────────────────────────────────────${C_RESET}"

  echo -e "\n  ${C_SKY}${IC_EDIT}  $(tr_text "Enter Author Name (leave empty to cancel):" "Masukkan Nama Author (kosongkan untuk batal):")${C_RESET}"
  read -e -r -i "$cur_name" -p "  ${IC_CHEV}  " NEW_NAME
  if [ -z "$NEW_NAME" ]; then
    msg_warn "$(tr_text "Canceled setting Git Author." "Batal mengatur Git Author.")"
    return 1
  fi

  echo -e "\n  ${C_SKY}${IC_EDIT}  $(tr_text "Enter Author Email (leave empty to cancel):" "Masukkan Email Author (kosongkan untuk batal):")${C_RESET}"
  read -e -r -i "$cur_email" -p "  ${IC_CHEV}  " NEW_EMAIL
  if [ -z "$NEW_EMAIL" ]; then
    msg_warn "$(tr_text "Canceled setting Git Author." "Batal mengatur Git Author.")"
    return 1
  fi

  if [[ "$NEW_EMAIL" != *"@"* ]]; then
    echo -ne "\n  ${C_AMBER}${IC_WARN}  $(tr_text "Email format does not contain '@'. Save '$NEW_EMAIL' anyway? (y/N): " "Format email tidak mengandung '@'. Tetap simpan '$NEW_EMAIL'? (y/N): ")${C_RESET}"
    read -r email_confirm
    if [[ ! "$email_confirm" =~ ^[Yy]$ ]]; then
      msg_warn "$(tr_text "Canceled." "Dibatalkan.")"
      return 1
    fi
  fi

  if git config "$scope_flag" user.name "$NEW_NAME" && git config "$scope_flag" user.email "$NEW_EMAIL"; then
    msg_ok "$(tr_text "Git Author (${scope_flag#--}) saved:" "Git Author (${scope_flag#--}) berhasil disimpan:") ${NEW_NAME} <${NEW_EMAIL}>"
    return 0
  else
    msg_err "$(tr_text "Failed to save Git Author configuration." "Gagal menyimpan konfigurasi Git Author.")"
    return 1
  fi
}

# Menghitung panjang teks bersih tanpa kode ANSI untuk alignment border kanan
strip_ansi_len() {
  local clean
  clean=$(printf '%b' "$1" | sed -r 's/\x1B\[[0-9;]*[mK]//g')
  echo "${#clean}"
}

# Mencetak baris isi di dalam Rounded Box dengan padding kanan presisi
print_box_row() {
  local content="$1"
  local box_width="$2"
  local inner_width=$((box_width - 4))
  local visible_len
  visible_len=$(strip_ansi_len "$content")
  local pad=$((inner_width - visible_len))
  [ "$pad" -lt 0 ] && pad=0
  printf "  ${C_BORDER}│${C_RESET} %b%*s ${C_BORDER}│${C_RESET}\n" "$content" "$pad" ""
}

render_header() {
  local repo_name="$1"
  local branch="$2"
  local staged="$3"
  local unstaged="$4"

  local term_cols
  term_cols=$(tput cols 2>/dev/null || echo 100)
  local box_width=$((term_cols - 4))
  [ "$box_width" -gt 132 ] && box_width=132
  [ "$box_width" -lt 68 ] && box_width=68

  local max_val_len=$((box_width - 24))
  local safe_repo safe_branch
  safe_repo=$(truncate_str "$repo_name" "$max_val_len")
  safe_branch=$(truncate_str "$branch" "$max_val_len")

  local line_bar
  line_bar=$(printf '─%.0s' $(seq 1 $((box_width - 2))))

  local delta_badge lang_badge
  if [ "$USE_DELTA" = true ]; then
    delta_badge="${C_SKY}delta:on${C_RESET}"
  else
    delta_badge="${C_MUTED}delta:off${C_RESET}"
  fi

  if [ "$TUI_LANG" = "id" ]; then
    lang_badge="${C_PERI}${IC_LANG}  ID${C_RESET}"
  else
    lang_badge="${C_PERI}${IC_LANG}  EN${C_RESET}"
  fi

  local changes_str
  if [ "$unstaged" -gt 0 ] || [ "$staged" -gt 0 ]; then
    changes_str=""
    [ "$staged" -gt 0 ] && changes_str+="${C_GREEN}${C_BOLD}${IC_PLUS}  ${staged} Staged${C_RESET}   "
    [ "$unstaged" -gt 0 ] && changes_str+="${C_RED}${C_BOLD}${IC_EDIT}  ${unstaged} Unstaged${C_RESET}"
  else
    changes_str="${C_GREEN}${IC_OK}  $(tr_text "Clean (Working tree clean)" "Clean (Working tree bersih)")${C_RESET}"
  fi

  local lbl_repo lbl_author lbl_branch lbl_upstream lbl_changes
  lbl_repo=$(printf "%-14s" "$(tr_text "Repository" "Repositori")")
  lbl_author=$(printf "%-14s" "$(tr_text "Author" "Penulis")")
  lbl_branch=$(printf "%-14s" "$(tr_text "Active Branch" "Branch Aktif")")
  lbl_upstream=$(printf "%-14s" "Upstream")
  lbl_changes=$(printf "%-14s" "$(tr_text "Changes" "Perubahan")")

  echo ""
  echo -e "  ${C_BORDER}╭${line_bar}╮${C_RESET}"
  print_box_row "${C_BLUE}${C_BOLD}${IC_GIT}  ARI-DEV GIT WORKSPACE${C_RESET}   ${C_MUTED}•${C_RESET}   ${delta_badge}   ${C_MUTED}•${C_RESET}   ${lang_badge}" "$box_width"
  echo -e "  ${C_BORDER}├${line_bar}┤${C_RESET}"
  print_box_row "${C_PERI}${IC_REPO}  ${lbl_repo}${C_MUTED}:${C_RESET} ${C_TEXT}${C_BOLD}${safe_repo}${C_RESET}" "$box_width"
  print_box_row "${C_PERI}${IC_USER}  ${lbl_author}${C_MUTED}:${C_RESET} $(git_author_status)" "$box_width"
  print_box_row "${C_PERI}${IC_GIT}  ${lbl_branch}${C_MUTED}:${C_RESET} ${C_SKY}${C_BOLD}${safe_branch}${C_RESET}" "$box_width"
  print_box_row "${C_PERI}${IC_SYNC}  ${lbl_upstream}${C_MUTED}:${C_RESET} $(upstream_status)" "$box_width"
  print_box_row "${C_PERI}${IC_STAGE}  ${lbl_changes}${C_MUTED}:${C_RESET} ${changes_str}" "$box_width"
  echo -e "  ${C_BORDER}╰${line_bar}╯${C_RESET}"
  echo ""
}

# ==============================================================================
# 6. MAIN INTERACTIVE LOOP
# ==============================================================================
while true; do
  clear
  REPO_ROOT=$(git rev-parse --show-toplevel)
  REPO_NAME=$(basename "$REPO_ROOT")
  CURRENT_BRANCH=$(git branch --show-current)
  [ -z "$CURRENT_BRANCH" ] && CURRENT_BRANCH="HEAD (detached)"

  UNSTAGED_COUNT=$(git status --porcelain | grep -c "^[ MADRC?][MD?]" || true)
  STAGED_COUNT=$(git status --porcelain | grep -c "^[MADRC]" || true)

  render_header "$REPO_NAME" "$CURRENT_BRANCH" "$STAGED_COUNT" "$UNSTAGED_COUNT"

  MAIN_HEADER=$(printf "%s\n%s\n%s" \
    "$(hint_2col "↑/↓" "$(tr_text "Navigate menu" "Navigasi menu")" "ENTER" "$(tr_text "Select action" "Pilih menu")")" \
    "$(hint_2col "TYPE" "$(tr_text "Quick filter" "Cari cepat")" "ESC" "$(tr_text "Refresh / Quit" "Refresh / Keluar")")" \
    "$(hint_divider)")

  MENU=$(
    cat <<EOF | tui_fzf "$(tr_text "MAIN MENU" "MENU UTAMA")" --height=74% --header="$MAIN_HEADER"
${IC_SEARCH}  $(tr_text "Search & Select Branch (Checkout / Merge)" "Cari & Pilih Branch (Checkout / Merge)")
${IC_REMOTE}  $(tr_text "Manage Remote" "Kelola Remote")
${IC_FETCH}  $(tr_text "Fetch Remote" "Fetch Remote")
${IC_PULL}  $(tr_text "Pull" "Pull")
${IC_PUSH}  $(tr_text "Push" "Push")
${IC_TAG}  $(tr_text "Tag Manager" "Kelola Tag")
${IC_HIST}  $(tr_text "History Commit" "Riwayat Commit")
${IC_ADD}  $(tr_text "Create New Branch" "Buat Branch Baru")
${IC_LINK}  $(tr_text "Set / Change Upstream" "Atur / Ubah Upstream")
${IC_USER}  $(tr_text "Git Author (Name & Email)" "Git Author (Nama & Email)")
${IC_STAGE}  $(tr_text "Stage & Commit" "Stage & Commit")
${IC_STAGE}  $(tr_text "Stash Changes" "Simpan Perubahan ke Stash")
${IC_PULL}  $(tr_text "Pop Stash" "Pop Stash")
${IC_TRASH}  $(tr_text "Discard Changes (Undo)" "Buang Perubahan (Undo)")
${IC_DIFF}  $(tr_text "Visual Diff (Branch / Folder / File)" "Visual Diff (Branch / Folder / File)")
${IC_FIRE}  $(tr_text "Bulk Delete Branches" "Hapus Massal Branch")
${IC_LANG}  $(tr_text "Language: English -> Bahasa Indonesia" "Bahasa: Indonesia -> English")
${IC_EXIT}  $(tr_text "Exit" "Keluar")
EOF
  )

  [ -z "$MENU" ] && continue

  case "$MENU" in

  # ============================================================================
  # LANGUAGE SWITCHER (EN <-> ID)
  # ============================================================================
  *"Language:"* | *"Bahasa:"*)
    toggle_language
    continue
    ;;

  # ============================================================================
  # GIT AUTHOR (NAME & EMAIL)
  # ============================================================================
  *"Git Author (Name & Email)"* | *"Git Author (Nama & Email)"*)
    while true; do
      LOC_NAME=$(git config --local user.name 2>/dev/null)
      LOC_EMAIL=$(git config --local user.email 2>/dev/null)
      GLOB_NAME=$(git config --global user.name 2>/dev/null)
      GLOB_EMAIL=$(git config --global user.email 2>/dev/null)

      UNSET_LABEL=$(tr_text "Not set" "Belum di-set")
      LOC_INFO="$UNSET_LABEL"
      if [ -n "$LOC_NAME" ] || [ -n "$LOC_EMAIL" ]; then
        LOC_INFO="${LOC_NAME:-"-"} <${LOC_EMAIL:-"-"}>"
      fi

      GLOB_INFO="$UNSET_LABEL"
      if [ -n "$GLOB_NAME" ] || [ -n "$GLOB_EMAIL" ]; then
        GLOB_INFO="${GLOB_NAME:-"-"} <${GLOB_EMAIL:-"-"}>"
      fi

      AUTHOR_HEADER=$(printf "%b\n%s\n%s" \
        "${C_PERI}Local ($REPO_NAME):${C_RESET} ${C_TEXT}$LOC_INFO${C_RESET}   ${C_MUTED}|${C_RESET}   ${C_PERI}Global:${C_RESET} ${C_TEXT}$GLOB_INFO${C_RESET}" \
        "$(hint_2col "ENTER" "$(tr_text "Select option" "Pilih opsi")" "ESC" "$(tr_text "Back to menu" "Kembali ke menu")")" \
        "$(hint_divider)")

      AUTHOR_MENU=$(
        cat <<EOF | tui_fzf "$(tr_text "GIT AUTHOR CONFIG" "KONFIGURASI GIT AUTHOR")" --height=52% \
          --header="$AUTHOR_HEADER"
${IC_REPO}  $(tr_text "Set Repository Author (Local)" "Set Author Repository Ini (Local)")
${IC_REMOTE}  $(tr_text "Set Global Author (All Repositories)" "Set Author Global (Semua Repository)")
${IC_TRASH}  $(tr_text "Remove Local Author (Fallback to Global)" "Hapus Author Local (Fallback ke Global)")
${IC_WARN}  $(tr_text "Remove Global Author" "Hapus Author Global")
${IC_BACK}  $(tr_text "Back" "Kembali")
EOF
      )
      RET=$?
      [ $RET -ne 0 ] && break
      [ -z "$AUTHOR_MENU" ] && break

      case "$AUTHOR_MENU" in
        *"Set Repository Author"* | *"Set Author Repository Ini"*)
          set_git_author "--local" "Repository ($REPO_NAME)"
          pause_tui
          ;;

        *"Set Global Author"* | *"Set Author Global"*)
          set_git_author "--global" "Global (~/.gitconfig)"
          pause_tui
          ;;

        *"Remove Local Author"* | *"Hapus Author Local"*)
          if [ -z "$LOC_NAME" ] && [ -z "$LOC_EMAIL" ]; then
            msg_info "$(tr_text "Repository '$REPO_NAME' has no local Author configuration." "Repository '$REPO_NAME' tidak memiliki konfigurasi Author lokal.")"
          else
            echo -ne "\n  ${C_AMBER}${IC_WARN}  $(tr_text "Remove local Author in '$REPO_NAME' and fallback to Global? (y/N): " "Hapus Author lokal di '$REPO_NAME' agar kembali memakai Global? (y/N): ")${C_RESET}"
            read -r CONFIRM_UNSET
            if [[ "$CONFIRM_UNSET" =~ ^[Yy]$ ]]; then
              git config --local --unset user.name 2>/dev/null || true
              git config --local --unset user.email 2>/dev/null || true
              msg_ok "$(tr_text "Local Author removed. Repository now uses Global configuration." "Author lokal dihapus. Repository sekarang mengikuti konfigurasi Global.")"
            else
              msg_warn "$(tr_text "Canceled." "Dibatalkan.")"
            fi
          fi
          pause_tui
          ;;

        *"Remove Global Author"* | *"Hapus Author Global"*)
          if [ -z "$GLOB_NAME" ] && [ -z "$GLOB_EMAIL" ]; then
            msg_info "$(tr_text "Global Author configuration is not set." "Konfigurasi Author Global memang belum di-set.")"
          else
            echo -ne "\n  ${C_RED}${IC_WARN}  $(tr_text "Remove Global Author ($GLOB_INFO)? (y/N): " "Hapus Author Global ($GLOB_INFO)? (y/N): ")${C_RESET}"
            read -r CONFIRM_UNSET
            if [[ "$CONFIRM_UNSET" =~ ^[Yy]$ ]]; then
              git config --global --unset user.name 2>/dev/null || true
              git config --global --unset user.email 2>/dev/null || true
              msg_ok "$(tr_text "Global Author configuration removed." "Konfigurasi Author Global telah dihapus.")"
            else
              msg_warn "$(tr_text "Canceled." "Dibatalkan.")"
            fi
          fi
          pause_tui
          ;;

        *"Back"* | *"Kembali"*)
          break
          ;;
      esac
    done
    ;;

  # ============================================================================
  # DISCARD CHANGES (UNDO) - Full-width Long Path + Bottom Preview
  # ============================================================================
  *"Discard Changes (Undo)"* | *"Buang Perubahan (Undo)"*)
    DISCARD_HEADER=$(printf "%s\n%s\n%s\n%s" \
      "$(hint_2col "TAB" "$(tr_text "Toggle select file" "Tandai / Pilih file")" "CTRL-A" "$(tr_text "Select all files" "Pilih semua file")")" \
      "$(hint_2col "ENTER" "$(tr_text "Proceed to confirm" "Lanjut konfirmasi")" "CTRL-D" "$(tr_text "Deselect all" "Batal pilih semua")")" \
      "$(hint_2col "ESC" "$(tr_text "Cancel & return" "Batal & kembali")" "" "")" \
      "$(hint_divider)")

    FILES_TO_DISCARD=$(git status --short | tui_fzf_path "$(tr_text "DISCARD CHANGES" "BUANG PERUBAHAN")" -m \
      --height=82% \
      --header="$DISCARD_HEADER" \
      --bind "ctrl-a:select-all" \
      --bind "ctrl-d:deselect-all" \
      --preview "
        file=\$(echo {} | sed -E 's/^.. //; s/^.* -> //; s/^\"(.*)\"\$/\1/')
        if git diff --cached --quiet -- \"\$file\" 2>/dev/null; then
          git diff --color=always -- \"\$file\" | sed '1,4d'
        else
          git diff --cached --color=always -- \"\$file\" | sed '1,4d'
        fi
        if [[ {} == '??'* ]]; then head -n 100 \"\$file\" 2>/dev/null; fi
      ")

    if [ -z "$FILES_TO_DISCARD" ]; then
      msg_warn "$(tr_text "Canceled: No files selected." "Batal: Tidak ada file yang dipilih.")"
    else
      CLEAN_FILES=$(echo "$FILES_TO_DISCARD" | extract_status_file)
      has_untracked=$(echo "$FILES_TO_DISCARD" | grep "^??" || true)

      echo -e "\n  ${C_AMBER}${C_BOLD}${IC_WARN}  $(tr_text "CONFIRM PERMANENT DISCARD:" "KONFIRMASI PENGHAPUSAN PERMANEN:")${C_RESET}"
      echo "$CLEAN_FILES" | sed "s/^/    ${C_SKY}${IC_FILE}${C_RESET}  /"
      echo -e "  ${C_BORDER}────────────────────────────────────────────────────────${C_RESET}"

      if [ -n "$has_untracked" ]; then
        echo -e "  ${C_RED}${C_BOLD}${IC_FIRE}  $(tr_text "DANGER: Selection includes UNTRACKED files that will be PHYSICALLY DELETED." "BAHAYA: Daftar mencakup FILE BARU (untracked) yang akan DIHAPUS FISIK.")${C_RESET}"
      fi

      echo -ne "\n  ${C_TEXT}$(tr_text "Are you sure you want to discard all selected changes? (y/N): " "Yakin ingin membuang semua perubahan ini? (y/N): ")${C_RESET}"
      read -r CONFIRM
      if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        msg_info "$(tr_text "Cleaning up selected files..." "Memproses pembersihan file...")"
        echo "$FILES_TO_DISCARD" | while IFS= read -r line; do
          file=$(echo "$line" | extract_status_file)
          if [[ "$line" == "??"* ]]; then
            rm -rf "$file"
          else
            git reset HEAD "$file" &>/dev/null
            git checkout -- "$file"
          fi
        done
        msg_ok "$(tr_text "All selected changes have been discarded." "Semua perubahan terpilih telah dibersihkan.")"
      else
        msg_warn "$(tr_text "Canceled." "Dibatalkan.")"
      fi
    fi
    pause_tui
    ;;

  # ============================================================================
  # VISUAL DIFF (BRANCH / FOLDER / FILE) - Full-width Long Path + Bottom Preview
  # ============================================================================
  *"Visual Diff"*)
    DIFF_MODE=$(printf "%s  %s\n%s  %s\n" \
      "$IC_REPO" "$(tr_text "Folder / Package" "Folder / Package")" \
      "$IC_FILE" "$(tr_text "Specific File" "File Spesifik")" | \
      tui_fzf "$(tr_text "DIFF MODE" "MODE DIFF")" --height=32%)
    [ -z "$DIFF_MODE" ] && continue

    BR_A=$(git branch -a | sed 's/^[* ]*//; s/remotes\///' | sort -u | \
      tui_fzf "$(tr_text "SELECT BRANCH A (BASE)" "PILIH BRANCH A (BASE)")" --height=48% "${FZF_PATH_OPTS[@]}")
    [ -z "$BR_A" ] && continue

    BR_B=$(git branch -a | sed 's/^[* ]*//; s/remotes\///' | sort -u | \
      tui_fzf "$(tr_text "SELECT BRANCH B (TARGET)" "PILIH BRANCH B (TARGET)")" --height=48% "${FZF_PATH_OPTS[@]}")
    [ -z "$BR_B" ] && continue

    if [[ "$DIFF_MODE" == *"Folder"* ]]; then
      FOLDER_DIFF_HEADER=$(printf "%s\n%s\n%s" \
        "$(hint_2col "ENTER" "$(tr_text "Open in Meld" "Buka di Meld")" "TYPE" "$(tr_text "Filter folder" "Cari folder")")" \
        "$(hint_2col "ESC" "$(tr_text "Back to main menu" "Kembali ke menu utama")" "" "")" \
        "$(hint_divider)")

      while true; do
        SEL_FOLDER=$(find . -maxdepth 8 -type d -not -path '*/.*' | \
          tui_fzf_path "FOLDER DIFF ($BR_A vs $BR_B)" \
            --height=82% \
            --header="$FOLDER_DIFF_HEADER" \
            --preview "ls -la --color=always {} 2>/dev/null | head -40")

        [ -z "$SEL_FOLDER" ] && break

        msg_info "$(tr_text "Opening Meld Directory Mode for:" "Membuka Meld Directory Mode untuk:") $SEL_FOLDER"
        git difftool --tool=meld -d "$BR_A" "$BR_B" -- "$SEL_FOLDER"
        msg_ok "$(tr_text "Folder review finished. Returning to list..." "Selesai review folder. Kembali ke daftar...")"
      done

    elif [[ "$DIFF_MODE" == *"File"* ]]; then
      FILE_DIFF_HEADER=$(printf "%s\n%s\n%s" \
        "$(hint_2col "ENTER" "$(tr_text "Choose review tool" "Pilih tool review")" "TYPE" "$(tr_text "Filter file" "Cari file")")" \
        "$(hint_2col "ESC" "$(tr_text "Back to main menu" "Kembali ke menu utama")" "" "")" \
        "$(hint_divider)")

      while true; do
        SEL_FILE=$(git ls-tree -r "$BR_A" --name-only | \
          tui_fzf_path "FILE DIFF ($BR_A vs $BR_B)" \
            --height=82% \
            --header="$FILE_DIFF_HEADER" \
            --preview "git diff --color=always $BR_A $BR_B -- {1}")

        [ -z "$SEL_FILE" ] && break

        SEL_FILE_BASE=$(basename "$SEL_FILE")
        ACTION=$(
          cat <<EOF | tui_fzf "$(tr_text "REVIEW TOOL:" "TOOL REVIEW:") $SEL_FILE_BASE" \
            --height=36% \
            --header="${C_PERI}${IC_FILE}  ${SEL_FILE}${C_RESET}"
${IC_DIFF}  Visual Meld (Side-by-Side)
${IC_FILE}  Terminal View (Fast)
${IC_BACK}  $(tr_text "Cancel" "Batal")
EOF
        )

        case "$ACTION" in
          *"Meld"*)
            git difftool --tool=meld --no-prompt "$BR_A" "$BR_B" -- "$SEL_FILE"
            ;;
          *"Terminal"*)
            if [ "$USE_DELTA" = true ]; then
              git diff --color=always "$BR_A" "$BR_B" -- "$SEL_FILE" | delta
            else
              git diff --color=always "$BR_A" "$BR_B" -- "$SEL_FILE" | less -R
            fi
            pause_tui
            ;;
          *)
            continue
            ;;
        esac
      done
    fi
    ;;

  # ============================================================================
  # BULK DELETE BRANCHES
  # ============================================================================
  *"Bulk Delete Branches"* | *"Hapus Massal Branch"*)
    MODE=$(
      cat <<EOF | tui_fzf "$(tr_text "BULK DELETE MODE" "MODE HAPUS MASSAL")" --height=32%
${IC_GIT}  Local Branches
${IC_REMOTE}  Remote Branches
${IC_BACK}  $(tr_text "Cancel" "Batal")
EOF
    )

    case "$MODE" in
      *"Local"*)
        CURRENT_BR=$(git branch --show-current)
        BULK_LOC_HEADER=$(printf "%b\n%s\n%s\n%s" \
          "${C_PERI}$(tr_text "Active branch (protected):" "Branch aktif (dilindungi):")${C_RESET} ${C_SKY}${C_BOLD}$CURRENT_BR${C_RESET}" \
          "$(hint_2col "TAB" "$(tr_text "Select branch" "Tandai branch")" "CTRL-A" "$(tr_text "Select all" "Pilih semua")")" \
          "$(hint_2col "ENTER" "$(tr_text "Continue" "Lanjutkan")" "CTRL-D" "$(tr_text "Deselect all" "Batal pilih")")" \
          "$(hint_divider)")

        BRANCHES_TO_DELETE=$(git for-each-ref --format='%(refname:short)' refs/heads/ |
          grep -v "^$CURRENT_BR$" |
          tui_fzf "$(tr_text "DELETE LOCAL BRANCHES" "HAPUS LOCAL BRANCHES")" -m \
            --height=70% \
            --header="$BULK_LOC_HEADER" \
            "${FZF_PATH_OPTS[@]}" \
            --bind "ctrl-a:select-all" \
            --bind "ctrl-d:deselect-all")

        if [ -n "$BRANCHES_TO_DELETE" ]; then
          OPT=$(printf "%s  Soft Delete (-d)\n%s  Force Delete (-D)\n" "$IC_TRASH" "$IC_FIRE" | \
            tui_fzf "$(tr_text "DELETE METHOD" "METODE HAPUS")" --height=30%)
          [ -z "$OPT" ] && continue

          echo -ne "\n  ${C_RED}${C_BOLD}${IC_FIRE}  $(tr_text "Delete selected local branches? (y/N): " "Yakin hapus branch lokal tersebut? (y/N): ")${C_RESET}"
          read -r confirm_del
          if [[ "$confirm_del" =~ ^[Yy]$ ]]; then
            FLAG="-d"
            [[ "$OPT" == *"Force"* ]] && FLAG="-D"
            echo "$BRANCHES_TO_DELETE" | xargs -I {} git branch "$FLAG" "{}"
            msg_ok "$(tr_text "Selected local branches deleted!" "Branch lokal terpilih berhasil dihapus!")"
          fi
        fi
        ;;

      *"Remote"*)
        REMOTE_NAME=$(git remote | tui_fzf "$(tr_text "SELECT REMOTE" "PILIH REMOTE")" --height=32%)
        [ -z "$REMOTE_NAME" ] && continue

        msg_info "$(tr_text "Syncing with" "Sinkronisasi dengan") $REMOTE_NAME..."
        git fetch "$REMOTE_NAME" --prune &>/dev/null

        BULK_REM_HEADER=$(printf "%s\n%s\n%s" \
          "$(hint_2col "TAB" "$(tr_text "Select branch" "Tandai branch")" "CTRL-A" "$(tr_text "Select all" "Pilih semua")")" \
          "$(hint_2col "ENTER" "$(tr_text "Delete from remote" "Hapus dari remote")" "CTRL-D" "$(tr_text "Deselect all" "Batal pilih")")" \
          "$(hint_divider)")

        BRANCHES_TO_DELETE=$(git for-each-ref --format='%(refname:short)' refs/remotes/"$REMOTE_NAME" |
          grep -v "/HEAD$" | sed "s#$REMOTE_NAME/##" |
          tui_fzf "$(tr_text "DELETE REMOTE BRANCHES" "HAPUS REMOTE BRANCHES") ($REMOTE_NAME)" -m \
            --height=70% \
            --header="$BULK_REM_HEADER" \
            "${FZF_PATH_OPTS[@]}" \
            --bind "ctrl-a:select-all" \
            --bind "ctrl-d:deselect-all")

        if [ -n "$BRANCHES_TO_DELETE" ]; then
          echo -e "\n  ${C_AMBER}${C_BOLD}${IC_WARN}  $(tr_text "WILL BE DELETED FROM REMOTE" "AKAN DIHAPUS DARI REMOTE") ($REMOTE_NAME):${C_RESET}"
          echo "$BRANCHES_TO_DELETE" | sed "s/^/    ${C_RED}${IC_GIT}${C_RESET}  /"
          echo -ne "\n  ${C_RED}${C_BOLD}${IC_FIRE}  $(tr_text "PERMANENTLY delete from remote server? (y/N): " "Yakin hapus PERMANEN di server? (y/N): ")${C_RESET}"
          read -r confirm_del
          if [[ "$confirm_del" =~ ^[Yy]$ ]]; then
            for br in $BRANCHES_TO_DELETE; do
              git push "$REMOTE_NAME" --delete "$br"
            done
            git fetch "$REMOTE_NAME" --prune &>/dev/null
            msg_ok "$(tr_text "Remote branches cleaned up!" "Remote branch berhasil dibersihkan!")"
          fi
        fi
        ;;
    esac
    pause_tui
    ;;

  # ============================================================================
  # STAGE & COMMIT - Full-width Long Path + Bottom Preview
  # ============================================================================
  *"Stage & Commit"*)
    STAGE_HEADER=$(printf "%s\n%s\n%s\n%s" \
      "$(hint_2col "TAB" "$(tr_text "Toggle select file" "Tandai / Pilih file")" "CTRL-A" "$(tr_text "Select all files" "Pilih semua file")")" \
      "$(hint_2col "ENTER" "$(tr_text "Stage & Commit" "Stage & Commit")" "CTRL-D" "$(tr_text "Deselect all" "Batal pilih semua")")" \
      "$(hint_2col "CTRL-R" "$(tr_text "Unstage all files" "Unstage semua file")" "ESC" "$(tr_text "Cancel & return" "Batal & kembali")")" \
      "$(hint_divider)")

    FILES=$(git status --short | tui_fzf_path "STAGE & COMMIT" -m \
      --height=82% \
      --header="$STAGE_HEADER" \
      --bind "ctrl-a:select-all" \
      --bind "ctrl-d:deselect-all" \
      --bind "ctrl-r:execute(git reset)+reload(git status --short)" \
      --preview "
        file=\$(echo {} | sed -E 's/^.. //; s/^.* -> //; s/^\"(.*)\"\$/\1/')
        if git diff --cached --quiet -- \"\$file\" 2>/dev/null; then
          git diff --color=always -- \"\$file\" | sed '1,4d'
        else
          git diff --cached --color=always -- \"\$file\" | sed '1,4d'
        fi
        if [[ {} == '??'* ]]; then head -n 100 \"\$file\" 2>/dev/null; fi
      ")

    if [ -z "$FILES" ]; then
      msg_info "$(tr_text "Exited stage menu." "Keluar dari menu stage.")"
      sleep 1
      continue
    fi

    CLEAN_FILES=$(echo "$FILES" | extract_status_file)

    echo -e "\n  ${C_BLUE}${C_BOLD}${IC_STAGE}  $(tr_text "Preparing files to stage:" "Menyiapkan file untuk stage:")${C_RESET}"
    echo "$CLEAN_FILES" | sed "s/^/    ${C_GREEN}${IC_PLUS}${C_RESET}  /"

    while IFS= read -r f; do
      [ -n "$f" ] && git add -- "$f"
    done <<< "$CLEAN_FILES"
    msg_ok "$(tr_text "Files staged successfully." "File berhasil di-stage.")"

    echo -ne "\n  ${C_SKY}${IC_EDIT}  $(tr_text "Enter commit message (leave empty to cancel): " "Masukkan pesan commit (kosongkan untuk batal): ")${C_RESET}"
    read -r MSG
    if [ -z "$MSG" ]; then
      msg_warn "$(tr_text "Commit canceled. Files remain staged." "Batal Commit. File tetap dalam kondisi staged.")"
    else
      git commit -m "$MSG"

      echo -ne "\n  ${C_SKY}${IC_PUSH}  $(tr_text "Push to remote now? (y/N): " "Push ke remote sekarang? (y/N): ")${C_RESET}"
      read -r PUSH_CONFIRM
      if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
        REMOTE=$(git remote | tui_fzf "$(tr_text "PUSH TO REMOTE" "PUSH KE REMOTE")" --height=32%)
        [ -z "$CURRENT_BRANCH" ] && CURRENT_BRANCH=$(git branch --show-current)
        [ -n "$REMOTE" ] && git push "$REMOTE" "$CURRENT_BRANCH"
      fi
    fi
    pause_tui
    ;;

  # ============================================================================
  # STASH CHANGES
  # ============================================================================
  *"Stash Changes"* | *"Simpan Perubahan ke Stash"*)
    if [ -z "$(git status --porcelain)" ]; then
      msg_info "$(tr_text "There are no changes to stash." "Tidak ada perubahan untuk disimpan ke stash.")"
    else
      echo -ne "\n  ${C_SKY}${IC_STAGE}  $(tr_text "Stash message (leave empty for default): " "Pesan stash (kosongkan untuk pesan bawaan): ")${C_RESET}"
      read -r STASH_MESSAGE

      if [ -n "$STASH_MESSAGE" ]; then
        if git stash push -m "$STASH_MESSAGE"; then
          msg_ok "$(tr_text "Changes saved to stash." "Perubahan berhasil disimpan ke stash.")"
        else
          msg_err "$(tr_text "Failed to stash changes." "Gagal menyimpan perubahan ke stash.")"
        fi
      elif git stash push; then
        msg_ok "$(tr_text "Changes saved to stash." "Perubahan berhasil disimpan ke stash.")"
      else
        msg_err "$(tr_text "Failed to stash changes." "Gagal menyimpan perubahan ke stash.")"
      fi
    fi
    pause_tui
    ;;

  # ============================================================================
  # POP STASH
  # ============================================================================
  *"Pop Stash"*)
    STASH_LIST=$(git stash list --format='%gd %cr %s')
    if [ -z "$STASH_LIST" ]; then
      msg_info "$(tr_text "There are no stashes to pop." "Tidak ada stash untuk di-pop.")"
    else
      SELECTED_STASH=$(printf '%s\n' "$STASH_LIST" | \
        tui_fzf "$(tr_text "SELECT STASH TO POP" "PILIH STASH UNTUK DI-POP")" \
          --height=52% \
          --header="$(hint_2col "ENTER" "$(tr_text "Pop selected stash" "Pop stash terpilih")" "ESC" "$(tr_text "Cancel" "Batal")")")

      if [ -n "$SELECTED_STASH" ]; then
        STASH_REF="${SELECTED_STASH%% *}"
        if git stash pop "$STASH_REF"; then
          msg_ok "$(tr_text "Stash applied and removed:" "Stash berhasil diterapkan dan dihapus:") $STASH_REF"
        else
          msg_err "$(tr_text "Could not pop stash. Resolve any conflicts; the stash is retained." "Stash gagal di-pop. Selesaikan konflik jika ada; stash tetap tersimpan.") $STASH_REF"
        fi
      fi
    fi
    pause_tui
    ;;

  # ============================================================================
  # SET / CHANGE UPSTREAM
  # ============================================================================
  *"Set / Change Upstream"* | *"Atur / Ubah Upstream"*)
    msg_info "$(tr_text "Setting Upstream for branch:" "Mengatur Upstream untuk branch:") ${C_BOLD}$CURRENT_BRANCH${C_RESET}"
    SELECTED_REMOTE=$(git remote | tui_fzf "$(tr_text "SELECT TARGET REMOTE" "PILIH REMOTE TUJUAN")" --height=32%)

    if [ -n "$SELECTED_REMOTE" ]; then
      msg_info "$(tr_text "Syncing" "Sinkronisasi") '$CURRENT_BRANCH' -> '$SELECTED_REMOTE'..."
      if git push -u "$SELECTED_REMOTE" "$CURRENT_BRANCH"; then
        msg_ok "$(tr_text "Branch '$CURRENT_BRANCH' is now tracking '$SELECTED_REMOTE/$CURRENT_BRANCH'." "Branch '$CURRENT_BRANCH' sekarang tracking ke '$SELECTED_REMOTE/$CURRENT_BRANCH'.")"
      else
        msg_err "$(tr_text "Failed to push / set-upstream." "Gagal melakukan push / set-upstream.")"
      fi
    else
      msg_warn "$(tr_text "Canceled: No remote selected." "Batal: Remote tidak dipilih.")"
    fi
    pause_tui
    ;;

  # ============================================================================
  # CREATE NEW BRANCH
  # ============================================================================
  *"Create New Branch"* | *"Buat Branch Baru"*)
    msg_info "$(tr_text "Creating new branch from base:" "Membuat branch baru dari base:") ${C_BOLD}$CURRENT_BRANCH${C_RESET}"
    echo -ne "\n  ${C_SKY}${IC_ADD}  $(tr_text "New branch name (empty to cancel): " "Nama branch baru (kosong = batal): ")${C_RESET}"
    read -r NEW_BRANCH_NAME

    if [ -z "$NEW_BRANCH_NAME" ]; then
      msg_warn "$(tr_text "Branch creation canceled." "Batal membuat branch.")"
      sleep 1
    else
      if git checkout -b "$NEW_BRANCH_NAME"; then
        msg_ok "$(tr_text "Switched to new branch:" "Berhasil pindah ke branch baru:") $NEW_BRANCH_NAME"
        CURRENT_BRANCH="$NEW_BRANCH_NAME"

        echo -ne "\n  ${C_SKY}${IC_PUSH}  $(tr_text "Push & set upstream to remote now? (y/N): " "Langsung push & set upstream ke remote? (y/N): ")${C_RESET}"
        read -r push_confirm
        if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
          SELECTED_REMOTE=$(git remote | tui_fzf "$(tr_text "SELECT TARGET REMOTE" "PILIH REMOTE TUJUAN")" --height=32%)
          if [ -n "$SELECTED_REMOTE" ]; then
            msg_info "$(tr_text "Pushing to" "Memulai push ke") $SELECTED_REMOTE..."
            git push -u "$SELECTED_REMOTE" "$NEW_BRANCH_NAME"
            msg_ok "$(tr_text "Branch '$NEW_BRANCH_NAME' synced with '$SELECTED_REMOTE'." "Branch '$NEW_BRANCH_NAME' tersinkron dengan '$SELECTED_REMOTE'.")"
            pause_tui
          else
            msg_warn "$(tr_text "No remote selected; upstream not set." "Remote tidak dipilih, upstream belum di-set.")"
            sleep 1
          fi
        fi
      else
        msg_err "$(tr_text "Failed to create branch." "Gagal membuat branch.")"
        pause_tui
      fi
    fi
    ;;

  # ============================================================================
  # MANAGE REMOTE
  # ============================================================================
  *"Manage Remote"* | *"Kelola Remote"*)
    while true; do
      REMOTE_MENU=$(
        cat <<EOF | tui_fzf "$(tr_text "MANAGE REMOTE" "KELOLA REMOTE")" --height=44%
${IC_LIST}  $(tr_text "List Remotes" "Daftar Remote")
${IC_ADD}  $(tr_text "Add Remote" "Tambah Remote")
${IC_EDIT}  $(tr_text "Rename Remote" "Ubah Nama Remote")
${IC_TRASH}  $(tr_text "Delete Remote" "Hapus Remote")
${IC_FETCH}  $(tr_text "Fetch Remote" "Fetch Remote")
${IC_BACK}  $(tr_text "Back" "Kembali")
EOF
      )
      RET=$?
      [ $RET -ne 0 ] && break
      [ -z "$REMOTE_MENU" ] && break

      case "$REMOTE_MENU" in
        *"List Remotes"* | *"Daftar Remote"*)
          git remote | tui_fzf "$(tr_text "REMOTE LIST" "DAFTAR REMOTE")" --height=46% \
            --preview='echo "Remote : {}"; echo "URL    : $(git remote get-url {} 2>/dev/null)"'
          ;;

        *"Add Remote"* | *"Tambah Remote"*)
          echo -ne "\n  ${C_SKY}${IC_REMOTE}  $(tr_text "New remote name (empty = cancel): " "Nama remote baru (kosong = batal): ")${C_RESET}"
          read -r REMOTE_NAME
          [ -z "$REMOTE_NAME" ] && continue

          echo -ne "  ${C_SKY}${IC_LINK}  $(tr_text "Remote URL (empty = cancel): " "URL remote (kosong = batal): ")${C_RESET}"
          read -r REMOTE_URL
          [ -z "$REMOTE_URL" ] && continue

          git remote add "$REMOTE_NAME" "$REMOTE_URL" &&
            msg_ok "$(tr_text "Remote '$REMOTE_NAME' added successfully." "Remote '$REMOTE_NAME' berhasil ditambahkan.")"
          pause_tui
          ;;

        *"Rename Remote"* | *"Ubah Nama Remote"*)
          OLD_REMOTE=$(git remote | tui_fzf "$(tr_text "SELECT REMOTE" "PILIH REMOTE")" --height=46% \
            --preview='echo "Remote : {}"; echo "URL    : $(git remote get-url {} 2>/dev/null)"')
          [ -z "$OLD_REMOTE" ] && continue

          echo -e "\n  ${C_TEXT}$(tr_text "Current remote" "Remote saat ini") : ${C_SKY}$OLD_REMOTE${C_RESET}"
          echo -e "  ${C_TEXT}URL            : ${C_MUTED}$(git remote get-url "$OLD_REMOTE")${C_RESET}"

          echo -ne "\n  ${C_SKY}${IC_EDIT}  $(tr_text "New remote name (empty = cancel): " "Nama remote baru (kosong = batal): ")${C_RESET}"
          read -r NEW_REMOTE
          [ -z "$NEW_REMOTE" ] && continue

          git remote rename "$OLD_REMOTE" "$NEW_REMOTE" &&
            msg_ok "$(tr_text "Renamed remote:" "Nama remote diubah:") '$OLD_REMOTE' -> '$NEW_REMOTE'"
          pause_tui
          ;;

        *"Delete Remote"* | *"Hapus Remote"*)
          DEL_REMOTE=$(git remote | tui_fzf "$(tr_text "DELETE REMOTE" "HAPUS REMOTE")" --height=46% \
            --preview='echo "Remote : {}"; echo "URL    : $(git remote get-url {} 2>/dev/null)"')
          [ -z "$DEL_REMOTE" ] && continue

          echo -ne "\n  ${C_RED}${IC_WARN}  $(tr_text "Delete remote '$DEL_REMOTE'? [y/N]: " "Yakin hapus remote '$DEL_REMOTE'? [y/N]: ")${C_RESET}"
          read -r CONFIRM
          [[ "$CONFIRM" =~ ^[Yy]$ ]] || continue

          git remote remove "$DEL_REMOTE" &&
            msg_ok "$(tr_text "Remote '$DEL_REMOTE' removed." "Remote '$DEL_REMOTE' dihapus.")"
          pause_tui
          ;;

        *"Fetch Remote"*)
          FETCH_REMOTE=$(git remote | tui_fzf "FETCH REMOTE" --height=46% \
            --preview='echo "Remote : {}"; echo "URL    : $(git remote get-url {} 2>/dev/null)"')
          [ -z "$FETCH_REMOTE" ] && continue

          git fetch "$FETCH_REMOTE"
          pause_tui
          ;;

        *"Back"* | *"Kembali"*)
          break
          ;;
      esac
    done
    ;;

  # ============================================================================
  # PULL
  # ============================================================================
  *"Pull"*)
    REMOTE=$(git remote | tui_fzf "$(tr_text "SELECT REMOTE TO PULL" "PILIH REMOTE PULL")" --height=32%)
    [ -z "$REMOTE" ] && continue

    PULL_MODE=$(
      cat <<EOF | tui_fzf "PULL MODE ($REMOTE/$CURRENT_BRANCH)" --height=36%
${IC_PULL}  Pull (merge)
${IC_SYNC}  Pull (rebase)
${IC_FIRE}  Pull (HARD RESET)
${IC_BACK}  $(tr_text "Cancel" "Batal")
EOF
    )

    case "$PULL_MODE" in
      *HARD*)
        confirm "$(tr_text "HARD RESET to $REMOTE/$CURRENT_BRANCH?" "HARD RESET ke $REMOTE/$CURRENT_BRANCH?")" || continue
        git fetch "$REMOTE" &&
          git reset --hard "$REMOTE/$CURRENT_BRANCH"
        pause_tui
        ;;
      *merge* | *rebase*)
        if is_dirty; then
          DIRTY_ACTION=$(
            cat <<EOF | tui_fzf "$(tr_text "DIRTY WORKING TREE" "WORKING TREE KOTOR")" --height=34%
${IC_STAGE}  $(tr_text "Stash changes then pull" "Stash perubahan lalu pull")
${IC_FIRE}  $(tr_text "Force hard reset then pull" "Force reset lalu pull")
${IC_BACK}  $(tr_text "Cancel" "Batal")
EOF
          )
          case "$DIRTY_ACTION" in
            *Stash*) git stash push -u -m "auto-stash before pull" ;;
            *Force*)
              confirm "$(tr_text "Hard reset before pull?" "Reset hard sebelum pull?")" || continue
              git reset --hard
              ;;
            *) continue ;;
          esac
        fi

        if [[ "$PULL_MODE" == *rebase* ]]; then
          git pull --rebase "$REMOTE" "$CURRENT_BRANCH"
        else
          git pull "$REMOTE" "$CURRENT_BRANCH"
        fi
        pause_tui
        ;;
    esac
    ;;

  # ============================================================================
  # PUSH
  # ============================================================================
  *"Push"*)
    REMOTE=$(git remote | tui_fzf "$(tr_text "SELECT REMOTE TO PUSH" "PILIH REMOTE PUSH")" --height=32%)
    [ -z "$REMOTE" ] && continue

    PUSH_ACTION=$(
      cat <<EOF | tui_fzf "$(tr_text "PUSH TO" "PUSH KE") '$REMOTE'" --height=36%
${IC_PUSH}  $(tr_text "Push active branch ($CURRENT_BRANCH)" "Push branch aktif ($CURRENT_BRANCH)")
${IC_GIT}  $(tr_text "Push all branches" "Push semua branch")
${IC_TAG}  $(tr_text "Push all tags" "Push semua tag")
${IC_BACK}  $(tr_text "Cancel" "Batal")
EOF
    )

    case "$PUSH_ACTION" in
      *"active branch"* | *"branch aktif"*) git push "$REMOTE" "$CURRENT_BRANCH" ;;
      *"all branches"* | *"semua branch"*) git push "$REMOTE" --all ;;
      *"all tags"* | *"semua tag"*) git push "$REMOTE" --tags ;;
    esac
    pause_tui
    ;;

  # ============================================================================
  # TAG
  # ============================================================================
  *"Tag Manager"* | *"Kelola Tag"*)
    while true; do
      TAG_MENU=$(
        cat <<EOF | tui_fzf "$(tr_text "TAG MANAGER" "MANAJER TAG")" --height=34%
${IC_ADD}  $(tr_text "Create Tag" "Buat Tag")
${IC_LIST}  $(tr_text "List Tags" "Daftar Tag")
${IC_BACK}  $(tr_text "Back" "Kembali")
EOF
      )
      case "$TAG_MENU" in
        *"Create Tag"* | *"Buat Tag"*)
          echo -ne "\n  ${C_SKY}${IC_TAG}  $(tr_text "Tag name: " "Nama tag: ")${C_RESET}"
          read -r TAG_NAME
          [ -z "$TAG_NAME" ] && continue
          if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
            msg_err "$(tr_text "Tag '$TAG_NAME' already exists." "Tag '$TAG_NAME' sudah ada.")"
            pause_tui
            continue
          fi
          echo -ne "  ${C_SKY}${IC_EDIT}  $(tr_text "Tag message (empty = lightweight): " "Pesan tag (kosong = lightweight): ")${C_RESET}"
          read -r TAG_MSG
          if [ -z "$TAG_MSG" ]; then
            git tag "$TAG_NAME"
          else
            git tag -a "$TAG_NAME" -m "$TAG_MSG"
          fi
          msg_ok "$(tr_text "Tag '$TAG_NAME' created successfully." "Tag '$TAG_NAME' berhasil dibuat.")"
          pause_tui
          ;;
        *"List Tags"* | *"Daftar Tag"*)
          TAG_LIST_HEADER=$(printf "%s\n%s" \
            "$(hint_2col "ENTER" "$(tr_text "Tag actions" "Aksi tag")" "ESC" "$(tr_text "Back" "Kembali")")" \
            "$(hint_divider)")

          while true; do
            TAG=$(git tag --sort=-creatordate | tui_fzf "$(tr_text "SELECT TAG" "PILIH TAG")" --height=58% \
              --header="$TAG_LIST_HEADER" \
              --preview "git show --color=always {} | head -80")
            [ -z "$TAG" ] && break

            TAG_ACTION=$(
              cat <<EOF | tui_fzf "$(tr_text "TAG ACTIONS:" "AKSI TAG:") '$TAG'" --height=36%
${IC_PUSH}  $(tr_text "Push tag to remote" "Push tag ke remote")
${IC_TRASH}  $(tr_text "Delete tag" "Hapus tag")
${IC_FILE}  $(tr_text "View tag details" "Lihat detail tag")
${IC_BACK}  $(tr_text "Back" "Kembali")
EOF
            )
            case "$TAG_ACTION" in
              *"Push tag"*)
                REMOTE=$(git remote | tui_fzf "$(tr_text "TARGET REMOTE" "REMOTE TUJUAN")" --height=32%)
                [ -n "$REMOTE" ] && git push "$REMOTE" "$TAG"
                ;;
              *"Delete tag"* | *"Hapus tag"*)
                OPT=$(
                  cat <<EOF | tui_fzf "$(tr_text "DELETE TAG" "HAPUS TAG") '$TAG'" --height=34%
${IC_TRASH}  $(tr_text "Delete LOCAL tag" "Hapus tag LOCAL")
${IC_REMOTE}  $(tr_text "Delete REMOTE tag" "Hapus tag REMOTE")
${IC_BACK}  $(tr_text "Cancel" "Batal")
EOF
                )
                case "$OPT" in
                  *LOCAL*)
                    confirm "$(tr_text "Delete local tag '$TAG'?" "Hapus tag local '$TAG'?")" && git tag -d "$TAG"
                    ;;
                  *REMOTE*)
                    REMOTE=$(git remote | tui_fzf "$(tr_text "SELECT REMOTE" "PILIH REMOTE")" --height=32%)
                    if [ -n "$REMOTE" ] && confirm "$(tr_text "Delete remote tag '$TAG' on '$REMOTE'?" "Hapus tag remote '$TAG' di '$REMOTE'?")"; then
                      git push "$REMOTE" ":refs/tags/$TAG"
                    fi
                    ;;
                esac
                ;;
              *"View tag"* | *"Lihat detail"*)
                git show "$TAG" | less -R
                ;;
            esac
          done
          ;;
        *) break ;;
      esac
    done
    ;;

  # ============================================================================
  # FETCH REMOTE
  # ============================================================================
  *"Fetch Remote"*)
    REMOTE=$(git remote | tui_fzf "$(tr_text "SELECT REMOTE TO FETCH" "PILIH REMOTE FETCH")" --height=32%)

    if [ -z "$REMOTE" ]; then
      msg_warn "$(tr_text "Canceled: No remote selected." "Batal: Tidak ada remote yang dipilih.")"
    else
      ACTION=$(
        cat <<EOF | tui_fzf "$(tr_text "FETCH ACTION" "AKSI FETCH") ($REMOTE)" --height=34%
${IC_FETCH}  $(tr_text "Normal Fetch" "Fetch Normal")
${IC_SYNC}  $(tr_text "Fetch & Prune (Clean stale remote branches)" "Fetch & Prune (Bersihkan branch mati)")
${IC_BACK}  $(tr_text "Cancel" "Batal")
EOF
      )

      case "$ACTION" in
        *"Normal Fetch"* | *"Fetch Normal"*)
          msg_info "$(tr_text "Fetching from" "Fetching dari") $REMOTE..."
          git fetch "$REMOTE"
          msg_ok "$(tr_text "Fetch completed." "Fetch selesai.")"
          ;;
        *"Fetch & Prune"*)
          msg_info "$(tr_text "Fetching & Pruning from" "Fetching & Pruning dari") $REMOTE..."
          git fetch "$REMOTE" --prune
          msg_ok "$(tr_text "Stale remote branches on '$REMOTE' pruned from local list." "Branch mati di remote '$REMOTE' sudah dibersihkan dari list lokal.")"
          ;;
        *)
          msg_warn "$(tr_text "Canceled." "Batal.")"
          ;;
      esac
    fi
    pause_tui
    ;;

  # ============================================================================
  # SEARCH & SELECT BRANCH
  # ============================================================================
  *"Search & Select Branch"* | *"Cari & Pilih Branch"*)
    BRANCH_SEL_HEADER=$(printf "%s\n%s" \
      "$(hint_2col "ENTER" "$(tr_text "Select branch" "Pilih branch")" "ESC" "$(tr_text "Back to menu" "Kembali ke menu")")" \
      "$(hint_divider)")

    SELECTED_BRANCH=$(git branch -a | sed 's/^[* ] //' | sed 's#remotes/##' | sort -u | \
      tui_fzf "$(tr_text "SELECT BRANCH" "PILIH BRANCH")" --height=58% \
        --header="$BRANCH_SEL_HEADER" \
        "${FZF_PATH_OPTS[@]}" \
        --preview "git log -n 15 --oneline --graph --color=always {}")

    [ -z "$SELECTED_BRANCH" ] && continue

    ACTION=$(
      cat <<EOF | tui_fzf "$(tr_text "ACTION:" "AKSI:") $(basename "$SELECTED_BRANCH")" \
        --height=40% \
        --header="${C_PERI}${IC_GIT}  ${SELECTED_BRANCH}${C_RESET}"
${IC_GIT}  $(tr_text "Checkout to LOCAL" "Checkout ke LOCAL")
${IC_MERGE}  $(tr_text "Merge into active branch ($CURRENT_BRANCH)" "Merge ke branch aktif ($CURRENT_BRANCH)")
${IC_FIRE}  $(tr_text "Delete LOCAL Branch (Force)" "Hapus Branch LOCAL (Force)")
${IC_TRASH}  $(tr_text "Delete REMOTE Branch" "Hapus Branch REMOTE")
${IC_BACK}  $(tr_text "Cancel" "Batal")
EOF
    )

    case "$ACTION" in
      *Checkout*)
        if git show-ref --verify --quiet "refs/heads/$SELECTED_BRANCH"; then
          git switch "$SELECTED_BRANCH"
        else
          REMOTE_NAME=$(cut -d/ -f1 <<<"$SELECTED_BRANCH")
          BRANCH_NAME=$(cut -d/ -f2- <<<"$SELECTED_BRANCH")
          git switch -c "$BRANCH_NAME" "$REMOTE_NAME/$BRANCH_NAME"
        fi
        ;;

      *Merge*)
        msg_info "$(tr_text "Merging '$SELECTED_BRANCH' into '$CURRENT_BRANCH'..." "Mencoba menggabungkan '$SELECTED_BRANCH' ke '$CURRENT_BRANCH'...")"

        if git merge "$SELECTED_BRANCH"; then
          msg_ok "$(tr_text "Merged cleanly without conflicts." "Berhasil digabungkan tanpa konflik.")"
          pause_tui
        else
          msg_warn "$(tr_text "MERGE CONFLICT detected!" "Terjadi MERGE CONFLICT!")"

          RESOLVE_TOOL=$(
            cat <<EOF | tui_fzf "$(tr_text "RESOLVE CONFLICT TOOL" "TOOL RESOLVE KONFLIK")" --height=40%
${IC_TOOL}  Sublime Merge (recommended)
${IC_TOOL}  IntelliJ IDEA
${IC_DIFF}  Meld
${IC_HIST}  $(tr_text "Later (manual resolve)" "Nanti (resolve manual)")
EOF
          )

          case "$RESOLVE_TOOL" in
            *Sublime*)
              msg_info "$(tr_text "Opening Sublime Merge..." "Membuka Sublime Merge...")"
              git config --local merge.tool smerge
              git config --local mergetool.prompt false
              git mergetool
              ;;
            *IntelliJ*)
              msg_info "$(tr_text "Opening IntelliJ IDEA..." "Membuka IntelliJ IDEA...")"
              git config --local merge.tool idea
              git config --local mergetool.prompt false
              git mergetool
              ;;
            *Meld*)
              msg_info "$(tr_text "Opening Meld..." "Membuka Meld...")"
              git config --local merge.tool meld
              git config --local mergetool.prompt false
              git mergetool
              ;;
            *)
              msg_warn "$(tr_text "Resolve postponed (status is still MERGING)." "Resolve ditunda (status masih MERGING).")"
              echo -e "  ${C_TEXT}$(tr_text "Manual commands:" "Perintah manual:") ${C_SKY}git status ${C_MUTED}| ${C_SKY}git mergetool ${C_MUTED}| ${C_SKY}git merge --abort${C_RESET}"
              pause_tui
              continue
              ;;
          esac

          if git diff --name-only --diff-filter=U | grep -q .; then
            msg_err "$(tr_text "There are still unresolved conflicts." "Masih ada konflik yang belum diselesaikan.")"
            pause_tui
            continue
          fi

          msg_ok "$(tr_text "All conflicts resolved." "Semua konflik berhasil diselesaikan.")"
          echo -ne "\n  ${C_SKY}${IC_STAGE}  $(tr_text "Complete merge commit now? (y/N): " "Lanjutkan commit merge sekarang? (y/N): ")${C_RESET}"
          read -r do_commit
          if [[ "$do_commit" =~ ^[Yy]$ ]]; then
            git commit --no-edit
            msg_ok "$(tr_text "Merge completed and committed." "Merge selesai dan sudah di-commit.")"
          else
            msg_info "$(tr_text "Merge staged, not yet committed (use Stage & Commit menu)." "Merge siap, belum di-commit (bisa lewat menu Stage & Commit).")"
          fi
          pause_tui
        fi
        ;;

      *"Delete LOCAL Branch"* | *"Hapus Branch LOCAL"*)
        echo -ne "\n  ${C_RED}${IC_TRASH}  $(tr_text "Delete LOCAL branch '$SELECTED_BRANCH'? (y/N): " "Yakin hapus branch LOCAL '$SELECTED_BRANCH'? (y/N): ")${C_RESET}"
        read -r confirm_del
        if [[ "$confirm_del" =~ ^[Yy]$ ]]; then
          git branch -D "$SELECTED_BRANCH"
          pause_tui
        else
          msg_warn "$(tr_text "Canceled." "Dibatalkan.")"
        fi
        ;;

      *"Delete REMOTE Branch"* | *"Hapus Branch REMOTE"*)
        if [[ "$SELECTED_BRANCH" == *"/"* ]]; then
          REMOTE_NAME=$(cut -d/ -f1 <<<"$SELECTED_BRANCH")
          BRANCH_NAME=$(cut -d/ -f2- <<<"$SELECTED_BRANCH")

          echo -ne "\n  ${C_RED}${C_BOLD}${IC_WARN}  $(tr_text "DANGER: Delete REMOTE branch '$REMOTE_NAME/$BRANCH_NAME'? (y/N): " "BAHAYA: Hapus branch REMOTE '$REMOTE_NAME/$BRANCH_NAME'? (y/N): ")${C_RESET}"
          read -r confirm_del
          if [[ "$confirm_del" =~ ^[Yy]$ ]]; then
            git push "$REMOTE_NAME" --delete "$BRANCH_NAME"
            pause_tui
          else
            msg_warn "$(tr_text "Canceled." "Dibatalkan.")"
          fi
        else
          msg_err "$(tr_text "'$SELECTED_BRANCH' is not a remote branch (missing remote prefix)." "'$SELECTED_BRANCH' bukan remote branch (tidak ada remote prefix).")"
          pause_tui
        fi
        ;;
    esac
    ;;

  # ============================================================================
  # HISTORY COMMIT
  # ============================================================================
  *"History Commit"* | *"Riwayat Commit"*)
    while true; do
      LOCAL_COMMITS=$(git cherry -v 2>/dev/null | gawk '{print $2}')

      HIST_HEADER=$(printf "%b\n%s\n%s" \
        "${C_AMBER}${C_BOLD}[L]${C_RESET} ${C_TEXT}= $(tr_text "Unpushed Local Commit" "Commit Lokal Belum Di-push")${C_RESET}   ${C_MUTED}|${C_RESET}   ${C_PERI}${IC_MERGE}  Merge${C_RESET}   ${C_SKY}${IC_COMMIT}  Commit${C_RESET}" \
        "$(hint_2col "ENTER" "$(tr_text "Inspect / Reset commit" "Detail / Reset commit")" "ESC" "$(tr_text "Back to menu" "Kembali ke menu")")" \
        "$(hint_divider)")

      COMMIT_LINE=$(
        git log --first-parent \
          --date=format:'%Y-%m-%d %H:%M' \
          --pretty=format:'%h|%ad|%an|%p|%s' \
          --shortstat |
          gawk -v local_list="$LOCAL_COMMITS" \
               -v ic_merge="$IC_MERGE" \
               -v ic_commit="$IC_COMMIT" \
               -v ic_cal="$IC_CAL" \
               -v ic_user="$IC_USER" \
               -v ic_plus="$IC_PLUS" \
               -v ic_minus="$IC_MINUS" '
          BEGIN {
            hash=""; date=""; author=""; parents=""; subject="";
            added=0; deleted=0;
            split(local_list, locals, " ");
            for (i in locals) local_map[locals[i]] = 1;
          }
          /^[0-9a-f]+\|/ {
            if (hash != "") {
              type_icon = (split(parents,p," ") > 1) ? "\033[38;2;180;190;254m" ic_merge "\033[0m" : "\033[38;2;125;207;255m" ic_commit "\033[0m"
              loc_tag = (hash in local_map) ? " \033[1;38;2;224;175;104m[L]\033[0m" : "    "
              printf "\033[1;38;2;122;162;247m%-8s\033[0m%s  \033[38;2;86;95;137m%s  %-16s\033[0m  \033[38;2;180;190;254m%s  %-12s\033[0m  %s   \033[38;2;158;206;106m%s  %-4d\033[0m  \033[38;2;247;118;142m%s  %-4d\033[0m  %s\n",
                    hash, loc_tag, ic_cal, date, ic_user, author, type_icon, ic_plus, added, ic_minus, deleted, subject
            }
            split($0, a, "|")
            hash=a[1]; date=a[2]; author=a[3]; parents=a[4]; subject=a[5]
            added=0; deleted=0
            next
          }
          /insertions?/ { match($0, /([0-9]+) insertion/, m); if (m[1] != "") added=m[1] }
          /deletions?/ { match($0, /([0-9]+) deletion/, m); if (m[1] != "") deleted=m[1] }
          END {
            if (hash != "") {
              type_icon = (split(parents,p," ") > 1) ? "\033[38;2;180;190;254m" ic_merge "\033[0m" : "\033[38;2;125;207;255m" ic_commit "\033[0m"
              loc_tag = (hash in local_map) ? " \033[1;38;2;224;175;104m[L]\033[0m" : "    "
              printf "\033[1;38;2;122;162;247m%-8s\033[0m%s  \033[38;2;86;95;137m%s  %-16s\033[0m  \033[38;2;180;190;254m%s  %-12s\033[0m  %s   \033[38;2;158;206;106m%s  %-4d\033[0m  \033[38;2;247;118;142m%s  %-4d\033[0m  %s\n",
                    hash, loc_tag, ic_cal, date, ic_user, author, type_icon, ic_plus, added, ic_minus, deleted, subject
            }
          }
        ' | tui_fzf "$(tr_text "COMMIT HISTORY" "RIWAYAT COMMIT") ($CURRENT_BRANCH)" \
            --height=78% \
            --header="$HIST_HEADER" \
            --preview "git show --color=always {1} | head -200"
      )

      [ -z "$COMMIT_LINE" ] && break

      COMMIT_HASH=$(gawk '{print $1}' <<<"$COMMIT_LINE")
      COMMIT_SUBJ=$(git log -1 --pretty=format:'%s' "$COMMIT_HASH")
      IS_LOCAL=$(echo "$LOCAL_COMMITS" | grep "$COMMIT_HASH" || true)

      MENU_OPTIONS="${IC_SEARCH}  $(tr_text "View Changed Files (Diff)" "Lihat List File (Diff)")\n"
      if [ -n "$IS_LOCAL" ]; then
        MENU_OPTIONS+="${IC_EDIT}  $(tr_text "Edit Commit Message (Local)" "Edit Pesan Commit (Local)")\n"
      fi
      MENU_OPTIONS+="${IC_SYNC}  Reset Mixed\n"
      MENU_OPTIONS+="${IC_FIRE}  Reset Hard\n"
      MENU_OPTIONS+="${IC_BACK}  $(tr_text "Cancel" "Batal")"

      ACTION=$(echo -e "$MENU_OPTIONS" | tui_fzf "COMMIT [$COMMIT_HASH]" \
        --height=38% \
        --header="$COMMIT_SUBJ")

      case "$ACTION" in
        *"View Changed Files"* | *"Lihat List File"*)
          PARENT_COUNT=$(git cat-file -p "$COMMIT_HASH" | grep -c '^parent ' || true)
          BASE_COMMIT=$([ "$PARENT_COUNT" -gt 1 ] && echo "$COMMIT_HASH^1" || echo "$COMMIT_HASH^")
          FILE_LIST=$(git diff --name-only "$BASE_COMMIT" "$COMMIT_HASH")

          while true; do
            FILE_PATH=$(echo "$FILE_LIST" | tui_fzf_path "$(tr_text "CHANGED FILES" "FILE BERUBAH") [$COMMIT_HASH]" \
              --height=82% \
              --preview "git diff --color=always $BASE_COMMIT $COMMIT_HASH -- {1} | sed '1,4d'")

            [ -z "$FILE_PATH" ] && break

            FILE_BASE=$(basename "$FILE_PATH")
            TOOL_OPTS="${IC_DIFF}  Visual Meld (3-Way/Side-by-Side)\n"
            [ "$USE_KOMPARE" = true ] && TOOL_OPTS+="${IC_DIFF}  Visual Kompare (KDE Native)\n"
            TOOL_OPTS+="${IC_FILE}  Terminal View (Fast)\n"
            TOOL_OPTS+="${IC_BACK}  $(tr_text "Cancel" "Batal")"

            TOOL_ACTION=$(echo -e "$TOOL_OPTS" | tui_fzf "$(tr_text "OPEN" "BUKA") '$FILE_BASE'" \
              --height=36% \
              --header="${C_PERI}${IC_FILE}  ${FILE_PATH}${C_RESET}")

            case "$TOOL_ACTION" in
              *"Meld"*)
                msg_info "$(tr_text "Opening Meld..." "Membuka Meld...")"
                git difftool --tool=meld --no-prompt "$BASE_COMMIT" "$COMMIT_HASH" -- "$FILE_PATH"
                ;;
              *"Kompare"*)
                msg_info "$(tr_text "Opening Kompare..." "Membuka Kompare...")"
                git difftool --tool=kompare --no-prompt "$BASE_COMMIT" "$COMMIT_HASH" -- "$FILE_PATH"
                ;;
              *"Terminal"*)
                if [ "$USE_DELTA" = true ]; then
                  git diff --color=always "$BASE_COMMIT" "$COMMIT_HASH" -- "$FILE_PATH" | delta
                else
                  git diff --color=always "$BASE_COMMIT" "$COMMIT_HASH" -- "$FILE_PATH" | less -R
                fi
                pause_tui
                ;;
              *)
                continue
                ;;
            esac
          done
          ;;

        *"Edit Commit Message"* | *"Edit Pesan Commit"*)
          LATEST_HASH=$(git rev-parse --short HEAD)
          if [ "$COMMIT_HASH" == "$LATEST_HASH" ]; then
            git commit --amend
          else
            msg_info "$(tr_text "Opening interactive rebase for older commit..." "Membuka rebase interaktif untuk commit lama...")"
            sleep 1
            git rebase -i "$COMMIT_HASH^"
          fi
          ;;

        *"Reset Mixed"*)
          git reset --mixed "$COMMIT_HASH"
          msg_ok "$(tr_text "Reset Mixed to $COMMIT_HASH completed." "Reset Mixed ke $COMMIT_HASH berhasil.")"
          pause_tui
          break
          ;;

        *"Reset Hard"*)
          echo -ne "\n  ${C_RED}${C_BOLD}${IC_WARN}  $(tr_text "PERMANENTLY DISCARD all changes back to $COMMIT_HASH? (y/N): " "HAPUS PERMANEN semua perubahan ke $COMMIT_HASH? (y/N): ")${C_RESET}"
          read -r confirm_reset
          if [[ "$confirm_reset" =~ ^[Yy]$ ]]; then
            git reset --hard "$COMMIT_HASH"
            msg_ok "$(tr_text "Reset Hard to $COMMIT_HASH completed." "Reset Hard ke $COMMIT_HASH selesai.")"
            pause_tui
            break
          fi
          ;;
      esac
    done
    ;;

  # ============================================================================
  # EXIT
  # ============================================================================
  *"Exit"* | *"Keluar"*)
    clear
    echo -e "\n  ${C_BLUE}${C_BOLD}${IC_GIT}  $(tr_text "ARI-DEV Git Workspace closed. See you!" "ARI-DEV Git Workspace ditutup. Sampai jumpa!")${C_RESET}\n"
    break
    ;;
  esac
done