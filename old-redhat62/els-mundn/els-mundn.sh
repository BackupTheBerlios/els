alias vi="vim"
export CVSROOT=/u1/CVS
function pro ()
{
    if [ -d ~/$1 ]; then
        cd ~/$1
        test -f .env && . .env
        test -d CVS && echo "Tipp doch mal mal 'cvs update' ein ...'
    else
        echo "Project directory /home/$USER/$1 does not exist"
    fi
}
