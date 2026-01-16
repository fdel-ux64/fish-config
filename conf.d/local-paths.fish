# Add local-only function and completion directories
set -l local_func_dir ~/.config/fish/functions/local
set -l local_comp_dir ~/.config/fish/completions/local

if test -d $local_func_dir
    set -g fish_function_path $local_func_dir $fish_function_path
end

if test -d $local_comp_dir
    set -g fish_complete_path $local_comp_dir $fish_complete_path
end
