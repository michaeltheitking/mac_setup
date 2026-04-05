# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

#if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
#  eval "$(oh-my-posh init zsh)"
#fi


export PATH="$HOME/.local/bin:$PATH"

awssync() {
  aws s3 sync . s3://michael-king.com --delete \
    --exclude ".*" \
    --exclude ".*/**" \
    --exclude ".*/**" \
    --exclude "README.md" \
    --exclude "package.json" \
    --exclude "package-lock.json" \
    --exclude "yarn.lock" \
    --exclude "pnpm-lock.yaml" \
    --exclude "node_modules" \
    --exclude "node_modules/*" \
    --exclude "node_modules/**" \
    --exclude "tests" \
    --exclude "tests/*" \
    --exclude "tests/**" \
    --exclude "test" \
    --exclude "test/*" \
    --exclude "test/**" \
    --exclude "*.map" \
  && aws cloudfront create-invalidation --distribution-id E2LXTUFU951CL5 --paths "/*" > /dev/null \
  && echo "CloudFront cache invalidated."
}

dbox() {
  cd ~/Dropbox/website
}

alias claudeauto='claude --enable-auto-mode'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[[ -f ~/.zshrc.private ]] && source ~/.zshrc.private
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
