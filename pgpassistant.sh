#!/bin/bash
enableDecryption=1 #Global variable to enable/disable the DTPA's encryption functionality. Set to 0 to disable, 1 to enable.
addressLogTime=7 #Global variable that determines the amount of days Signed PGP Messages containing deposit addresses are stored. Set this to 0 if you do not want to store these messages at all.
addressLogEncryptionKey="" #Global variable that determines with which key the deposit addresses are encrypted before storage. Set this to the username of your public key if you want to encrypt the Signed PGP Messages containing Monero or Bitcoin deposit addresses before storing them. Leave the quotes where they are, type the username in between them. Leave blank if you do not wish to encrypt these stored messages.
encryptForMeKey="" #If you want all messages encrypted by the DTPA to also be encrypted with your own key for later reference, add the username of your public key here. (leave the quotes where they are, type the username in between them)
recipientListCount=8 #Sets the amount of recent users in your GPG keyring that is shown in the decryption popup screen for replying to messages. You may increase or decrease this as you see fit.
enableAutoCorrect=1 #Global variable to enable/disable the DTPA's autocorrect functionality. Set to 0 to disable, 1 to enabled. When enabled, all PGP blocks which have at least 1 leading and 1 trailing '-' character get corrected to a real PGP block with 5 leading and trailing '-' characters. Enabling this function prevents errors from occurring if you accidentally miss a character when copying PGP blocks to clipboard. It also removed leading spaces, which can accidentally be added to the clipboard when working with Virtualbox and not having Guest-to-host drag&drop functionality enabled properly.
kleopatraLock=0 #Global variable that determines whether or not the DTPA will process the clipboard contents if Kleopatra has an open window. For value 0 the DTPA will always process the clipboard, for value 1, the DTPA will not process the clipboard if Kleopatra has an open window.
kleopatraLockWarning=1 #Global variable that in the event the kleopatraLock is set to 1, determines whether or not the user will receive an info message from the DTPA stating it will no longer be processing the clipboard because Kleopatra is active.
enableCertificationStrictMode=0 #Global variable to enable/disable the strictness of verifying signed messages. If set to 1, verification shows a success message only if the owner's public key in your keyring was certified. If set to 0, signed messages are still show a success message even if the sender's public key in your keyring was not certified, alongside a warning saying that the key is not certified.
enableImportCertification=1 #Global variable to enable/disable automatically certifying keys when they are imported. Set to 1 to enable, 0 to disable.

tmpOutputPrefix="/tmp/darknet-tools" #the name prefix of all temporary files where DTPA output is stored.
fileCount=0 #the filecount of the output files, to allow every file to have a unique name. Using the same file name causes the text editor to pop up a reload file request prompt, which prevents the user from instantly getting a new popup if the previous window is still open (which is always the case for actions such as key imports and replying to a decrypted message)
importConfirmTitle="Confirm Public Key Import! Make sure you got it from a verified source!" #Shared text variable to handle processing of key import confirmation
encryptActionTitle='______________________________________DTPA ACTION: ENCRYPT______________________________________' #Shared text variable to handle encryption
encryptRecipientTitle="___________________________________DTPA ENCRYPTION: RECIPIENT___________________________________" #Shared text variable to handle processing recipients during encryption
encryptMessageTitle="____________________________________DTPA ENCRYPTION: MESSAGE____________________________________" #Shared text variable to handle processing the message during encryption
lastClippedOnion="" #Stores the last Onion that was copied to clipboard for later reference during mirror verification
lastClippedKey="" #Stores the last Public Key that was copied to clipboard for import for later reference in case the user want to send a message to this key
tmpOutput="" #Global variable to contain the output that will be displayed to the user.

if [[ "$(xclip -version 2>&1 1>/dev/null)" == *'xclip: command not found' ]] #if xclip is not available on the system, notify the user and exit
then
    printf -- '%b' 'xclip is not available on this system, please install it before using the Darknet Tools PGP Assistant.\nRun the command: sudo apt install -y xclip\n'
    exit
fi

if [[ "$(mousepad --version 2>&1 1>/dev/null)" != *'mousepad: command not found' ]] #check if mousepad is available on the user's system, as is the default on Whonix
then #if so, use it as the text editor for displaying output 
    textEditor='mousepad --opening-mode=window'
elif [[ "$(gedit --version 2>&1 1>/dev/null)" != *'gedit: command not found' ]] #if not, check if gedit is availablle on the user's system, as is the default on Tails
then #if so, use it as the text editor for displaying output with the new window option 
    textEditor='gedit --new-window'
else #if neither mousepad nor gedit are available, rely on xdg-open to select the default text editor for displaying the output
    textEditor='xdg-open'
fi

if [[ "$(wmctrl --version 2>&1 1>/dev/null)" == *'wmctrl: command not found' ]] #if wmctrl is not available on the system, as is the default case for Tails, use pgrep instead to check if Kleopatra is active
then
    function CheckKleopatra() { pgrep kleopatra; } #in pgrep kleopatra is always all lower case
else
    function CheckKleopatra() { wmctrl -l|grep Kleopatra; } #in wmctrl Kleopatra is always with the first letter in upper case
fi

#initialize the global variable $addressLogPath 
if [[ -d /home/user ]] #check if on Whonix
then #if so set the addressLogPath to /home/user/DarknetTools/AddressLog
    addressLogPath='/home/user/DarknetTools/AddressLog'
elif [[ -d /home/amnesia ]] #check if on Tails
then #if so set the addressLogPath to /home/amnesia/Persistent/DarknetTools/AddressLog
    addressLogPath='/home/amnesia/Persistent/DarknetTools/AddressLog'
fi

if [[ ! -d "$addressLogPath"  ]] #check if the AddressLog directory exists
then
    mkdir -p "$addressLogPath" #If it doesn't, create it
else
    find "$addressLogPath" -type f -mtime +"$addressLogTime" -exec rm {} \; #if it does, delete stored deposit address message files older than the configured address log time
fi

rm "$tmpOutputPrefix"* 2> /dev/null #delete any lingering temporary files from last run of PGP Assistant in the /tmp directory. Note: these should get cleared automatically every reboot anyway.

function OutputInfo(){ #shortcut function for adding an info message to the output
    tmpOutput+="$(printf -- '###DTPA Info: %s' "$1\n")"
}

function OutputWarning(){ #shortcut function for adding a warning message to the output
    tmpOutput+="$(printf -- '###DTPA WARNING: %s\n' "$1\n")"
}

function OutputError(){ #shortcut function for adding an error message to the output
    tmpOutput+="$(printf -- '###DTPA ERROR: %s\n' "$1\n")"
}

function OutputPlain(){ #shortcut function for adding text without a prefix to the output
    tmpOutput+="$(printf -- '%s\n' "$1\n")"
}

function ShowOutput(){ #function to display the output that was assembled so far to the user
    if [ -n "$tmpOutput" ]
    then
        printf -- '\n\n%b' "$tmpOutput" #display in terminal
        printf -- '%b' "$tmpOutput" > "$tmpOutputPrefix$fileCount" #store in temporary text file
        $textEditor "$tmpOutputPrefix$fileCount" 2> /dev/null & #open temporary file in default text editor
        tmpOutput="" #reset the temporary output
        fileCount=$((fileCount+1)) #increase the file count for the next output
    fi
}

function HandleImportClip(){ #function to handle the importing of Public PGP Key Blocks that are present in the input parameter
    keyId="$(printf -- '%s' "$1"|gpg --list-packets --verbose --pinentry-mode cancel -- 2>&1)" #extract the key information from the copied public key
    keyId="$(printf -- '%s' "${keyId#*keyid: }"|sed -- '1q;d')" #extracts the key id from the key information
    if [[ "$keyId" == 'gpg: no valid OpenPGP data found.'
        || "$keyId" == 'gpg: invalid'*
        || "$keyId" == "gpg: [don't know]"* ]] #if the block contains an error message, inform the user of the error, stating his import could not be processed.
    	then
            OutputError "KEY COULD NOT BE PROCESSED! THE COPIED PUBLIC PGP KEY BLOCK CONTAINED INVALID DATA!"
	    OutputError "MAKE SURE YOU COPIED THE CORRECT KEY!"
	    OutputError "GPG output below:"
	    OutputPlain "$(printf -- '%b\n' "$1"|gpg --import -- 2>&1)"
	    ShowOutput
    elif gpg --list-secret-keys --with-colons|grep -qE -- "sec:.*:.*:.*:$keyId" #check if they key id belongs to a key of the user himself.
    then #if so, do not open the text editor popup, but do output the event to the terminal to inform the user the action. In most cases the user will have manually exported his own key from Kleopatra for use in setting up a new profile on some site/service. A popup requesting him to import this key would therefor not be helpful at all.
        printf -- '%b' "\n\nOwn public key copied to clipboard. Doing nothing."
    else #otherwise process the copied key
        if [ "$(printf -- '%s' "$1"|sed -- '1q;d')" == "###DTPA Info: $importConfirmTitle"  ] #check if the copied clipboard is a DTPA import confirmation or not
        then
            printf -- '%b' "$1" | gpg --import -- &> "$tmpOutputPrefix-handle-import-output.txt" #if it is a confirmation, do the import and store the gpg output in a temporary file
            if [[ "$(cat "$tmpOutputPrefix-handle-import-output.txt"|sed -- '1q;d')" == 'gpg: key '* ]] #check if the import was successful
            then #if so, set the last clipped key to the imported key to allow for sending a message to the owner of this key as the recipient.
                lastClippedKey="$(cat "$tmpOutputPrefix-handle-import-output.txt"|sed -- '1q;d')" #get the first line from the GPG import output
                lastClippedKey="${lastClippedKey%:*}" #cut everything including and after the last colon character
                lastClippedKey="${lastClippedKey##*gpg: key }" #cut everything up to and including the 'gpg: key ' part, leaving only the key id.
                OutputInfo "The import of the key(s) was completed successfully!"
                if [ "$enableImportCertification" -eq 1 ] #check if automatic certification is enabled
                then #if so, attempt to sign the newly imported key
                    signOutput="$(gpg --batch --yes --lsign-key -- "$lastClippedKey" 2>&1)" #sign the key to certify it
                    if printf -- '%s' "$signOutput" | grep -q -- 'gpg: signing failed' #check if the signing failed and add the result to the output
                    then
                        OutputError "An error occurred while certifying the key. If you want to certify it, please do so manually in Kleopatra!"
                    else
                        OutputInfo "The key was successfully certified!"
                    fi
                fi
                if [[ "$(cat "$tmpOutputPrefix-handle-import-output.txt"|tail -n 1)" == *" unchanged: "* ]] #check if an imported key was already present in the keyring
                then #if so, inform the user of this
                    OutputInfo "One or more of the imported key(s) were already present in your keyring and have been left unchanged."
                fi
                importState=1
            else #if the import was not successful, set the output to an error
                OutputError "KEY IMPORT FAILED!"
                OutputError "Make sure you copied the correct key"
                importState=0
            fi
            #show GPG output in both cases
            OutputInfo "See GPG Output Below:"
            OutputPlain "$(cat "$tmpOutputPrefix-handle-import-output.txt")"
            if [ "$importState" -eq 1 ] #if import was successful add the option to encrypt a response at the end of the output
            then
                OutputPlain "\n\n\n"
                OutputInfo "Do you wish to send an encrypted message to the owner of the imported pgp key?"
                OutputInfo "If yes, type the message under the 'DTPA ENCRYPTION: MESSAGE' line below and copy this entire text to clipboard (Ctrl+a, Ctrl+c)"
                OutputPlain "$encryptActionTitle"
                OutputPlain "$encryptMessageTitle\n"
            fi
        else #if the contents of the clipboard was not a confirmation, generate a confirmation message to import the public key
            OutputInfo "$importConfirmTitle"
            OutputInfo "Are you sure you want to import the key(s) below?"
            OutputInfo "To do so, copy this entire text to clipboard (Ctrl+a, Ctrl+c)!"
            if [ "$enableImportCertification" ] #check if certification is enabled and add info for the user in the case it is
            then
                OutputInfo "In order to certify the imported key, you will be prompted for your PGP passphrase to sign the new import if it is not already in cache."
            fi
            OutputPlain "\n$1"
        fi
        rm "$tmpOutputPrefix-handle-import-output.txt" 2>/dev/null #remove temporary file and ignore error message if it doesn't exist
	ShowOutput
    fi
}

function HandleSignatureClip(){ #function to handle verifying Signed PGP Messages that are present in the input parameter
    verificationOutput="$(printf -- '%s' "$1"|gpg --verify -- 2>&1)" #Perform the verification and store the output in a variable
    actualMessage="$1" #Prepare to get the actual message content without the surrounding PGP information. This is done to avoid a bitcoin address falsely being flagged if a random line in the signature starts with 'bc' and contains at least 42 subsequent alphanumerical characters.
    actualMessage="${actualMessage%%-----BEGIN PGP SIGNATURE-----*}" #Remove everything after and including the start of the BEGIN PGP SIGNATURE line
    actualMessage="${actualMessage##*-----BEGIN PGP SIGNED MESSAGE-----}" #Remove everything before and including the PGP SIGNED MESSAGE line
    if printf -- '%s' "$verificationOutput" | grep -q -- "^gpg: Good signature from " && #check if the signature was valid
    ( [[ "$enableCertificationStrictMode" -eq 0 ]] || ! printf -- '%s' "$verificationOutput" | grep -q -- 'gpg: WARNING: This key is not certified with a trusted signature!' ) #and check that either strictmode is disabled or there is no warning in the gpg output saying the key was not certified
    then #if it was, do further processing to check if it was an attempt to verify a mirror, or if it was to verify a deposit address
        if printf -- '%s' "$actualMessage"|grep -qE -- "[48][[:alnum:]]{94}" || printf -- '%s' "$actualMessage"|grep -qE -- "bc[[:alnum:]]{40}" #check if a Monero/Bitcoin address was present in the signed message
        then #if it was, store the message in the configured path if the user has configured a positive addressLogTime, if the user did not configure either of these, don't store the address and inform the user how they can configure this.
            OutputInfo "Signed message successfully verified!"
            if [[ -z "$addressLogPath" || "$addressLogTime" -eq 0 ]]
            then
                OutputInfo "A Monero/Bitcoin address was detected in the signed message, but you have configured the DTPA to not store deposit addresses"
                OutputInfo "To configure signed deposit addresses messages, change the 'addressLogTime' variable at the top of the DTPA script to a value greater than 0."
            else
                fileName="$(date +'%Y%m%d%H%M%S')" #set the filename of the stored deposit address message to the current date and time so the user can easily look up the corresponding entry if they end up having issues with their deposit going through (example: the filename would be '20230631162001' if the event occurs on the 31ste of June 2023, at 1 second past 4:20pm)
		if [ -z "$addressLogEncryptionKey" ] #check if the addressLogEncryptionKey is set
		then #if it is not, store the signed message containing the deposit address in plaintext in the configured addressLogPath with the datetime filename that was just generated
                    printf -- '%b\n' "$1" > "$addressLogPath/$fileName"
		else #if it is, first encrypt the signed message containing the deposit address with the configured addressLogEncryptionKey, then store it the same way as described above.
		    printf -- '%b' "$1" | gpg -ear "$addressLogEncryptionKey" -- > "$addressLogPath/$fileName"
                    encryptionInfix=" encrypted with key '$addressLogEncryptionKey', and" #add text in the middle of the output string informing the user of the encryption, alongside the storage
		fi
                OutputInfo "Signed message contained a Bitcoin or Monero address and was$encryptionInfix stored in your configured Address Log directory."
                OutputInfo "The full path to the stored file is $addressLogPath/$fileName."
            fi
        elif printf -- '%b' "$1"|grep -qE -- "\.onion" #check if the text .onion is present in the signed message to detect onions. Only check for .onion and not the full pattern to minimize the possibilities for avoiding the DTPA check with specifically crafted invalid onion links.
        then #if it was, try and compare it to the last clipped onion and generate an appropriate response.
            if [ -z "$lastClippedOnion" ] #check whether or not an onion was copied to clipboard first.
            then #if not, warn the user and inform him of the successful verification
                OutputWarning "ONION DETECTED IN SIGNED MESSAGE, BUT NO ONION WAS COPIED TO CLIPBOARD TO COMPARE IT TO"
                OutputWarning "If you were trying to verify mirrors, first copy the onion in your browser bar to clipboard before copying the signed mirror verification message to clipboard."    
                OutputInfo "If you were not trying to verify mirrors you may consider this message to be legitimate, as the signature was valid."        
            else
                if ! printf -- '%s' "$1"|grep -q -- "$lastClippedOnion" #if the onions don't match, warn the user that he is probably being phished
                then
                    OutputError "THE ONION DETECTED IN THE SIGNED MESSAGE DOES NOT MATCH THE ONION THAT WAS COPIED TO CLIPBOARD"
                    OutputError "YOU ARE LIKELY ON A PHISHING MIRROR!"
                    OutputInfo "If you want to try to find a verified mirror, visit daunt.link or tor.taxi"
                else #if they do match, inform the user of the successful verification
                    OutputInfo "Mirror verification was successful!"
                    OutputInfo "The signed message was successfully verified and the onion that was copied to your clipboard is present in the signed message!"
                fi 
            fi
        else #verify the message and check if there is an onion present in the signed message. If so warn the user and inform him how to verify a mirror properly
            OutputInfo "Signed message successfully verified!"
            OutputInfo "No onion links or deposit addresses detected in the message text."    
        fi
        if [ "$enableCertificationStrictMode" -eq 0 ] && printf -- '%s' "$verificationOutput" | grep -q -- 'gpg: WARNING: This key is not certified with a trusted signature!'
        then #if strictmode is disabled and the message was signed by a non-certified key, add a warning to the output
            OutputWarning "The public key of the person who signed this message has not yet been certified in your keyring!"
        fi
    else #if there was an error in the GPG output during the verification process, warn the user that he is likely being phished.
        OutputError "THE SIGNED MESSAGE IN CLIPBOARD COULD NOT BE VERIFIED!!!"
        OutputError "IF YOU WERE VERIFYING MIRRORS OR A DEPOSIT ADDRESS, YOU ARE LIKELY BEING PHISHED!!!"
    fi
    lastClippedOnion=""
    if printf -- '%s' "$verificationOutput" | grep -q -- 'gpg: Note: This key has expired!'
    then
        OutputWarning "The key this message was signed with has expired in your keyring!"
    fi
    OutputInfo "GPG OUTPUT BELOW:"
    OutputPlain "$verificationOutput" #Add the GPG output to the end of previously assembled output message for display to the user
    ShowOutput
}

function ListRecipients(){ #function to show the list of users for which there is an entry in the GPG keyring
    recipients="$(gpg --list-public-keys --with-colons --)" #get the base public key output from GPG
    recipients="$(printf -- '%s' "$recipients"|sed -rz -- 's/(pub[^\n]+\n)fpr[^\n]+\n(uid[^\n]+\n)+(sub[^\n]+\nfpr[^\n]+(\n)?)+/\2/g'|tail -n +2)" #only keep the last line of every entry, these lines contain the username of the key. Also cut the top line from the output because this contains irrelevant information.
    printf -- '%s' "$recipients" | sed -rz -- 's/uid:.:{4}[^:\n]+::[^:\n]+::([^:\n]+):[^\n]+\n?/\1\n/g' | tail -n "$recipientListCount" #extract the username from the remaining string and limit the output to the last 8 entries.
}

function HandleMessageClip(){ #function that handles automatically decrypting PGP messages that are passed in the input parameter.
    decryptedText="$(printf -- '%s' "$1"|gpg -d -- 2>"$tmpOutputPrefix-decryption-error")" #performs the decryption, stores the standard output in a variable and the error output in a temporary file.
    if cat "$tmpOutputPrefix-decryption-error" | grep -q -- "gpg: decryption failed: No secret key" ||
        cat "$tmpOutputPrefix-decryption-error" | grep -q -- "gpg: CRC error" #check whether or not there were errors in the decryption process.
    then #if there were errors, add an error message to the temporary output, include the GPG output
        OutputError "DECRYPTION FAILED!"
        OutputError "See GPG output below:"
        OutputPlain "$(cat "$tmpOutputPrefix-decryption-error")"
    else #if there weren't, set the temporary output to a success message containing the decrypted text, along with the option to encrypt a response, including a set of 8 possible recipients.
        OutputInfo "Decryption successful!"
        OutputInfo "See contents below"
        OutputPlain "$decryptedText"
	OutputPlain "\n\n"
        OutputInfo "To encrypt a quick response to this message, follow the steps below."
        OutputInfo "Type or copypaste the username of the public key of your recipient in the space between the '___DTPA ENCRYPTION: RECIPIENT___' and '___DTPA ENCRYPTION: MESSAGE___' lines."
        OutputInfo "Type the message you wish to encrypt below the '___DTPA ENCRYPTION: MESSAGE___' part."
        OutputInfo "To finish, copy this entire text to clipboard (Ctrl+a, Ctrl+c)"
        OutputInfo "Note: For convenience, the usernames of the 8 most recent key imports are listed!"
        OutputInfo "Note: If you wish to increase/decrease this number, adjust the value of the 'recipientListCount' variable at the top of the DTPA script!"
        OutputPlain "$encryptActionTitle"
        OutputPlain "$(ListRecipients)" #gets the 8 most recently imported keys for display as possible recipients
        OutputPlain "$encryptRecipientTitle"
        OutputPlain "\n\n$encryptMessageTitle\n"
    fi
    ShowOutput #display the assembled temporary output back to the user
    rm "$tmpOutputPrefix-decryption-error" 2> /dev/null #remove the temporary error file and ignore errors if it doesn't exist.
}

function ExtractRecipient(){ #function to extract the recipient from a DTPA Encrypt Action message
    recipient="$1" #set the recipient to the full string
    recipient="${recipient%%"$encryptMessageTitle"*}" #strip all text starting from the '___DTPA ENCRYPTION: MESSAGE___' string and onwards
    recipient="${recipient##*"$encryptRecipientTitle"}" #strip all text up until the '___DTPA ENCRYPTION: RECIPIENT___' string, so all that is left is the part where the recipient is located.
    recipient="$(printf -- '%s' "$recipient"|xargs)" #remove empty lines so all that is left is the recipient text
    printf -- '%s' "$recipient" #return the formatted recipient string back to the function caller
}

function HandleEncryptClip(){ #function to automatically encrypt a message after importing a new public key
    textToEncrypt="$1"
    textToEncrypt="${textToEncrypt##*"$encryptMessageTitle"}" #remove the non-message part of the copied text.
    textToEncrypt="$(printf -- '%s' "$textToEncrypt"|sed -rz -- 's/^(\n+)?([^\n].*(\n+)?$)/\2/')" #remove leading and trailing newline characters.
    if ! printf -- '%s' "$1"|grep -q -- "$encryptRecipientTitle" #check if the $encryptRecipientTitle is present in the input text.
    then #if not, this means it was an encryption request done after a key import, so set the recipient to the last clipped key
        recipient="$lastClippedKey"
    else #if yes, this means it was an encryption request done after decrypting a message, and the recipient should be in the __DTPA ENCRYPT: RECIPIENT__ section of the copied text.
        recipient="$(ExtractRecipient "$1")"
    fi
    if [ -z "$encryptForMeKey" ] #Check if the user has the encryptForMeKey set
    then #if not, only encrypt the text for the recipient
        encryptedText="$(printf -- '%s' "$textToEncrypt"|gpg --trust-model always -ear "$recipient" -- >&1 2> "$tmpOutputPrefix-encrypt-error.txt")" #perform the encryption
    else #if yes, encrypt the text for both the recipient and the user himself, using the set key in the $encryptForMeKey variable.
        encryptedText="$(printf -- '%s' "$textToEncrypt"|gpg --trust-model always -ea -r "$encryptForMeKey" -r "$recipient" -- >&1 2> "$tmpOutputPrefix-encrypt-error.txt")" #perform the encryption
    fi
    if [[ "$encryptedText" == '-----BEGIN PGP MESSAGE-----'*'-----END PGP MESSAGE-----' ]] #check if the encryption was successful.
    then #if it was, set the output to a success message and copy the encrypted message to clipboard.
        OutputInfo "Encryption complete"
        printf -- '%s' "$encryptedText" | xclip -selection c #copy encrypted text to clipboard
        lastClip="$encryptedText" #set lastClip variable to encrypted text, so it does not get processed by the DTPA for decryption
        OutputInfo "Encrypted message was copied to clipboard"
        OutputInfo "See a copy of the encrypted message text below:"
        OutputPlain "$encryptedText"
    else #if it wasn't set the output to an error message and append the encryption error to the output.
        OutputError "ENCRYPTION FAILED!"
        OutputError "SEE GPG OUTPUT BELOW"
        OutputPlain "$(cat "$tmpOutputPrefix-encrypt-error.txt")"
    fi
    rm "$tmpOutputPrefix"-encrypt-error.txt #remove the file with the error output
    lastClippedKey="" #clear the last clipped key
    ShowOutput #display the temporary assembled output back to the user
}

function HandleOnionClip(){ #function to handle copying an onion to clipboard for later user in verifying mirrors.
    cutOnion="$1"
    cutOnion="$(printf -- '%s' "$cutOnion" | sed -r -- 's|^https?://(www\.)?||')" #cut the leading http(s) part off the onion if it exists
    lastClippedOnion="${cutOnion%%.onion*}.onion" #cut any extranious suffixes off the onion if they exist and set the $lastClippedOnion variable.
    printf -- '\n\n%b\n' "Onion $lastClippedOnion successfully clipped to clipboard!" #output this clipboard event directly to terminal, without interruping the user with a popup text-editor.
}

if [ "$(xclip -selection c -o 2> /dev/null|shasum -a 256)" == "$(shasum -a 256 < "$0")" ] #check if the clipboard contents are equal to the contents of the DTPA script
then #if so, set the lastClip variable equal to the clipboard contents so the clipboard does not get processed and does not interrupt the user at the first launch with an irrelevant error message, due to of all the PGP patterns in the DTPA script.
    lastClip="$(xclip -selection c -o)"
fi

#Output an intro message so the user knows the DTPA is active and working.
printf -- '%s\n\n' 'Welcome to the Darknet Tools PGP Assistant! (v1.0)'
printf -- '%s\n' 'The DTPA is now watching your clipboard for patterns of Onion Links and PGP messages, signatures, and public keys.'
printf -- '%s\n\n' 'Any output that appears in popup windows of the default text editor will also appear here in this terminal window.'
printf -- '%s\n' 'If you are seeing this message, keep this window open! If you prefer to run the DTPA in the background instead, first close this instance of the DTPA by pressing Ctrl+c and then run the following command:'
printf -- '%s\n\n' "nohup $0 > $tmpOutputPrefix-stdout &"
printf -- '%s\n' 'If you like the DTPA and want to show your support, you can make a donation to the Monero address below:'
printf -- '%s\n\n' "85rnJSSWSxoWny7p88ZvJm4hYw3SKZm5M1S5dvnQcx9HJtYRkW3XufNWkvFFu6qQJENXNto8e9MFnVPNv4Pnso2M9o4PNWK"
printf -- '%b' 'I hope you enjoy the tool!\n\nSincerely,\nDarknet Tools\n'

while true #Main program. Check the clipboard every second to see if any Onion or PGP patterns are matched, if so, process the clipboard, afterwards sleep for a second.
do
    if [ "$enableAutoCorrect" -eq 1 ] #check if the autocorrect function is enabled
    then #if it is, correct mistakes such as leading spaces or missing dashes from copied PGP blocks if there are any.
        xclip -selection c -o 2> /dev/null | 
        sed -r -- 's/\-+BEGIN PGP([^\-]+)\-{5}/-----BEGIN PGP\1-----/'  | #fill in any missing '-' characters at the front of the block
        sed -r -- 's/\-{5}END PGP([^\-]+)\-+/-----END PGP\1-----/' | #fill in any missing '-' characters at the back of the block
        sed -r -- 's/[[:blank:]]+\-{5}BEGIN PGP/-----BEGIN PGP/'  | #remove any leading spaces/tabs from the front of the block
        sed -r -- 's/\-{5}END PGP([^\-]+)\-{5}[[:blank:]]+/-----END PGP\1-----/' | #remove any trailing spaces/tabs from the back of the block
        xclip -selection c
    fi
    clipboard="$(xclip -selection c -o 2>/dev/null)" #store the clipboard contents in a variable
    #check if the following conditions hold true. If so, process the clipboard, if not, do nothing.
    if [[ "$clipboard" != "$lastClip" #first, the clipboard contents must differ from the last entry processed by the DTPA
            && ( "$kleopatraLock" -eq 0 || -z "$(CheckKleopatra)" ) ]]  #second, either the kleopatraLock must be set to zero, or Kleopatra must not be detected to be running.
    then
        kleopatraWarningDone=0 #reset the kleopatraWarningDone variable, so that a new warning will be generated if Kleopatra reopens and the user has these warnings configured to be displayed
        lastClip="$clipboard" #set the last clipboard entry to the current clipboard contents so this clipboard entry will not be processed again after the processing that will take place now.
	if [[ "$(printf -- '%s' "$clipboard"|wc -l)" -eq 0 ]] && printf -- '%s' "$clipboard"|grep -qE -- "^(http)?.*\.onion/?.*$" #check if the clipboard fits the pattern of an Onion Link and if so, call the appropriate handler.
        then
    	    HandleOnionClip "$clipboard"
        elif [[ "$clipboard" == *"-----BEGIN PGP PUBLIC KEY BLOCK-----"*"-----END PGP PUBLIC KEY BLOCK-----"* ]] #check if the clipboard fits the pattern of a PGP Public Key, and if so call the appropriate handler.
        then
            HandleImportClip "$clipboard"
        elif [[ "$clipboard" == "-----BEGIN PGP SIGNED MESSAGE-----"*"-----END PGP SIGNATURE-----" ]] #check if the clipboard fits the pattern of a PGP Signed Message, and if so call the appropriate handler.
        then
	    HandleSignatureClip "$clipboard"
        elif [[ "$enableDecryption" -eq 1 && "$clipboard" == "-----BEGIN PGP MESSAGE-----"*"-----END PGP MESSAGE-----" ]] #check if the decryption functionality is enabled and if the clipboard fits the pattern of an encryped PGP Message and if both conditions are true, call the appropriate handler.
        then
	    HandleMessageClip "$clipboard"
        elif [[ "$clipboard" == *"$encryptActionTitle"* ]] #check if the clipboard contains the DTPA Encrypt Action and if so call the appropriate handler.
        then
	    HandleEncryptClip "$clipboard"
        fi
    elif [[ "$kleopatraLock" -eq 1 && -n "$(CheckKleopatra)" && "$kleopatraLockWarning" -eq 1 && "$kleopatraWarningDone" -eq 0 ]]
    then #if both the kleopatraLock and the kleopatraLockWarning are on, and Kleopatra is found to be running, inform the user that the DTPA will not process the clipboard until Kleopatra is exited.
        OutputInfo "Kleopatra was detected to be running, and the user has configured the kleopatraLock to be active."
        OutputInfo "The DTPA will no longer process the clipboard until the user exits Kleopatra\n"
        if [[ "$(wmctrl --version 2>&1 1>/dev/null)" == *'wmctrl: command not found' ]] 
        then #if the user is on a system without the wmctrl tool, inform them they need to explictly quit Kleopatra before the DTPA can process the clipboard again.
            OutputInfo "Remember to actually QUIT Kleopatra if you want the DTPA to process the clipboard again. Just closing the window still leaves Kleopatra running in the background"
            OutputInfo "Quitting can be done with the keyboard shortcut Ctrl+q, or by going to File -> Quit in the top menu of Kleopatra.\n"
        fi
        OutputInfo "To reconfigure the DTPA to always process the clipboard, even when Kleopatra is running, follow these steps:"
        OutputInfo " 1) Open the pgpassistant.sh script file in a text editor"
        OutputInfo " 2) Change the 'kleopatraLock' variable at the top of the script to 0"
        OutputInfo " 3) Save the file and restart the DTPA"  
        kleopatraWarningDone=1 #keep track of whether or not the warning has been issued already since the first time Kleopatra was detected to be active.
        ShowOutput #display the output to the user
    fi
    sleep 1 #sleep for 1 second before checking the clipboard contents again
done
