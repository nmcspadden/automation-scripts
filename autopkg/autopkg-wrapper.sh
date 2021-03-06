#!/bin/sh

# autopkg automation script which, when run with no arguments, checks current run's output against a default output and sends the output to a user if there are differences

# adjust the following variables for your particular configuration
recipe_list="AdobeAcrobatProXUpdate.munki AdobeAir.munki AdobeFlashPlayer.munki Compressor-MAS.munki FinalCutPro-MAS.munki FirefoxESR.munki GarageBand-MAS.munki GoogleChrome.munki GoogleEarth.munki iMovie-MAS.munki iPhoto-MAS.munki Keynote-MAS.munki minecraftedu.munki Motion-MAS.munki Numbers-MAS.munki OracleJava7.munki Pages-MAS.munki VLC.munki unitywebplayer.munki TextWrangler.munki MakeCatalogs.munki"
mail_recipient="nick.mcspadden@sacredsf.org"
autopkg_user="nmcspadden"

# don't change anything below this line

# define logger behavior
logger="/usr/bin/logger -t autopkg-wrapper"
user_home_dir=`dscl . -read /Users/${autopkg_user} NFSHomeDirectory | awk '{ print $2 }'`

# run autopkg
if [ "${1}" == "help" ]; then
  # show some help with regards to initialization option
  echo "usage: ${0} [initialize]"
  echo "(initializes a new default log for notification checking)"
  exit 0

elif [ "${1}" == "initialize" ]; then
  # initialize default log for automated run to check against for notification if things have changed
  $logger "starting autopkg to initialize a new default output log"

  echo "recipe list: ${recipe_list}"
  echo "autopkg user: ${autopkg_user}"
  echo "user home dir: ${user_home_dir}"

  # make sure Logs folder exists in autopkg_user's ~/Library/ folder
  if [ ! -d "${user_home_dir}"/Library/Logs/ ]; then
    /bin/mkdir -p "${user_home_dir}"/Library/Logs/
  fi

  # run autopkg twice, once to get any updates and the second to get a log indicating nothing changed
  $logger "autopkg initial run to temporary log location"
  echo "for this autopkg run, output will be shown"
  /usr/local/bin/autopkg run -v ${recipe_list} 2>&1

  $logger "autopkg initial run to saved log location"
  echo "for this autopkg run, output will not be shown, but rather saved to default log location (${user_home_dir}/Library/Logs/autopkg.out"
  /usr/local/bin/autopkg run ${recipe_list} 2>&1 > "${user_home_dir}"/Library/Logs/autopkg.out

  $logger "finished autopkg"

elif [ ! -f "${user_home_dir}"/Library/Logs/autopkg.out ]; then
  # default log doesn't exist, so tell user to run this script in initialization mode and exit
  echo "ERROR: default log does not exist, please run this script with initialize argument to initialize the log"
  exit -1

else
  # default is to just run autopkg and email log if something changed from normal
  $logger "starting autopkg"
  /usr/local/bin/autopkg run ${recipe_list} 2>&1 > /tmp/autopkg.out

  $logger "finished autopkg"

  # check output against the saved log and if differences exist, send current log to specified recipient
  if [ "`diff /tmp/autopkg.out \"${user_home_dir}\"/Library/Logs/autopkg.out`" != "" ]; then
    # there are differences from a "Nothing downloaded, packaged or imported" run... might be an update or an error
    $logger "sending autopkg log"
    /usr/bin/mail -s "autopkg log" ${mail_recipient}  < /tmp/autopkg.out
    $logger "sent autopkg log to {$mail_recipient}, `wc -l /tmp/autopkg.out | awk '{ print $1 }'` lines in log"
  else
    $logger "autopkg did nothing, so not sending log"
  fi
fi
exit 0

