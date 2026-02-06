function fish_user_key_bindings
    # Beep when backspace is used on an empty line, matching bash/readline behavior
    function __fish_backspace_with_bell --description 'Backspace with bell on empty prompt'
        if test (commandline -C) -eq 0
            # Send bell directly to the terminal so it fires even if stdout is redirected
            printf '\a' > /dev/tty
            return
        end

        commandline -f backward-delete-char
    end

    set -l modes (bind --list-modes)
    if not contains insert $modes
        set modes $modes insert
    end

    for mode in $modes
        # Clear existing backspace bindings so ours takes precedence
        bind --erase -M $mode -k backspace
        bind --erase -M $mode \x7f \b

        bind -M $mode -k backspace __fish_backspace_with_bell
        bind -M $mode \x7f __fish_backspace_with_bell
        bind -M $mode \b __fish_backspace_with_bell
    end
end
