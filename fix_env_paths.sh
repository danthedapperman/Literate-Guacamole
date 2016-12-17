#!/usr/bin/bash

#------------- what this is ---------------

# Replaces possibly incorrect hard paths to python in the virtualenv-generated scripts with this: 
#
# #!/usr/bin/env python
#
# These references occur in the first line of the scripts, as they instruct the shell to execute the file with python.
#
# In environments with spaces in the path (particularly Windows and cygwin envs) the spaces in the path will screw up the invocation of python by this line. So we replace it with a line that invokes python from a new shell with an inherited environment, which means it'll pick up the python from the path that had been set when the virtualenv was activated.

#------------- usage/how to invoke it ---------------

# $0 [project_dir] [env_full_path]
#
# Execute from the virtual evironment $WORKON_HOME subdirectory that is the parent of all your projects. In my case, this is $WORKON_HOME/Code
#
# OR
#
# Pass in the directory name of your project as the first argument (parent of the project bin dir)

# E.g., "$0 Alexa-Py27-Win"

# As an optional second argument, you can pass in the string location of the env executable in your environment. It cannot have any spaces in the path. If not specified, then /usr/bin/env will be assumed.

# E.g., "$0 Alexa-Py27-Win /usr/lib/bin/env"

#------------- begin code ---------------

#Store the list of files that need to be fixed
BINDIR="bin"
FILES="easy_install easy_install-2.7 pip pip2 pip2.7 wheel"
BACKUPSUFFIX="orig_before_fix"
PROJDIR=""
TMPEXPRFILE=".~tmpexpr"

#If the location of env.exe is different on your system, change PYTHONSTR or pass in the second argument to the command at execution. It must be a location with no spaces or strange chars
PYTHONSTR="/usr/bin/env python"

# Read the project directory name (if present) in from the args
# The project directory is where the bin directory exists
if [ -n "$1" ]; then
	# The user specified a project directory
	PROJDIR="$1/"
else 
	PROJDIR=""
fi


# If a second argument is specified, then use it as the path to the env.exe command.
if [ -n "$2" ]; then
	# using the user-specified string
	PYTHONSTR="$2 python"
	echo "Using the user-specified python invocation '$PYTHONSTR'"
else 
	# using the default set above
	PYTHONSTR=$PYTHONSTR
	echo "Using the default python invocation '$PYTHONSTR'"
fi

# Delimit the slashes in the python path so we can use the path in a regular expression
PYTHONREGEXP=$(echo "$PYTHONSTR" | sed 's/\//\\\//g')

echo "Fixing files in directory '$PROJDIR'"

# Iterate through the list of files that need to be fixed
# Fix them one at a time after making a backup copy
for f in $FILES
do
	fn=${PROJDIR}${BINDIR}/$f
	echo "Fixing file '$fn'"
	if [ -e $fn ]; then
		# Find out if we need to make a backup copy of the file
		# We only want to create a backup copy the FIRST time
		if [ -e $fn.$BACKUPSUFFIX ]; then
			echo "Backup of orignal already exists - $fn.$BACKUPSUFFIX"
		else
			# make a backup copy of the original
			echo "Copying original file to $fn.$BACKUPSUFFIX"
			cp $fn $fn.$BACKUPSUFFIX
		fi
		
		# read the file and use sed to replace the line that invokes python (overwriting the original file)
		
		# to make this dynamic and to make it actually work in a shell script, we'll write the sed regexp out to a temporary file and then tell sed to use the expression in the temp file
		if [ -e $TMPEXPRFILE ]; then
			echo "Error: the temporary regexp file already exists. Please delete $TMPEXPRFILE"
			exit 1
		fi
		echo "s/#!\"\/.*python\"$/#!${PYTHONREGEXP}/g" > $TMPEXPRFILE
		sed -i -f $TMPEXPRFILE $fn 
		rm $TMPEXPRFILE
		
		### this next line is the original cat invocation for history; it does not allow path to env to be changed in the arguments
		
		#cat $fn | sed 's/\!\"\/cygdrive\/c\/.*python\"$/\!\"\/usr\/bin\/env python\"/g' 
	else
		echo "File does not exist: '$fn'"
	fi
done
