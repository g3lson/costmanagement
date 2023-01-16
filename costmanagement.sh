#/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Variables globales:

parameter_counter=0
oC_parameter_counter=0
oN_parameter_counter=0
header_validation=0

# Functions:

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${redColour}[!] Saliendo...\n${endColour}"
    exit 1
}

function helpPanel(){
    echo -e "\n${redColour}[!] Uso: costmanagement${endColour}"
    for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
    echo -e "\n\n\t${blueColour}Help panel ${endColour}"
    echo -e "\n\t${grayColour} [-h]${endColour}${yellowColour} Show help panel menu ${endColour}"
    echo -e "\n\n\t${blueColour}Get consumption - Required ${endColour}"
    echo -e "\n\t${grayColour} [-s]${endColour}${yellowColour} Start date for consumption on Subscription: "aaaa-mm-dd" ${endColour}"
    echo -e "\n\t${grayColour} [-e]${endColour}${yellowColour} End date for consumption on Subscription: "aaaa-mm-dd"${endColour}"
    echo -e "\n\n\t${blueColour}Export output - Optional ${endColour}"
    echo -e "\n\t${grayColour} [-o]${endColour}${yellowColour} Export consumption result in normal output format - '"format table"'${endColour}"
    echo -e "\n\t${grayColour} [-v]${endColour}${yellowColour} Export consumption result in CSV output format - '"CSV format"'${endColour}"
    echo -e "\n\n\t${blueColour}Show consumption exported ${endColour}"
    echo -e "\n\t${grayColour} [-d]${endColour}${yellowColour} Display an existent CSV output format file on format table "format table"${endColour}"
    echo -e "\n${purpleColour} Example: costmanagement -s 2020-01-01 -e 2020-01-30 -o output.txt ${endColour}\n"
}

function display(){
    echo ""
    column -t -s ',' $display
    echo ""
}

while getopts "s:e:v:o:d:h:" arg; do
    case $arg in 
        e) end_date=$OPTARG; let parameter_counter+=1;;
        s) start_date=$OPTARG;;
        v) outputC=$OPTARG; let oC_parameter_counter+=1;;
        o) outputN=$OPTARG; let oN_parameter_counter+=1;;
        d) display=$OPTARG; let parameter_counter+=2;;
        h) helpPanel;;
    esac
done


if [[ $parameter_counter -eq 0 ]]; then
    helpPanel

elif [[ $parameter_counter -eq 2 ]]; then
    display

else
    
    function header_consumption (){
        echo -e "\n${grayColour}Subscription Name \t\t\t SuscriptionID \t\t\t\t\t Budget \t ActualCost \t Diferencia ${endColour}\n"
    }


    header_consumption
    for sub in $( curl https://raw.githubusercontent.com/holasoygelson/costmanagement/main/subs.txt 2> /dev/null ) ; do   
        sub_id=$( echo $sub | cut -d ',' -f1 )
        budget=$( echo $sub | cut -d ',' -f2 )
        subscription_name=$(az account show --subscription $sub_id --query name)
        actual_cost=$(az consumption usage list --subscription $sub_id --start-date $start_date --end-date $end_date --query [].pretaxCost --only-show-errors | cut -d '"' -f2 | tail -n +2 | grep -v ']' | awk '{n += $1}; END{print n}' | cut -d '.' -f1)
            
        if [[ "$actual_cost" == '' ]]; then     
                actual_cost=0
        fi

        diferencial_consumption=$(( $budget - $actual_cost ))
        if [[ "$diferencial_consumption" -lt '0' ]]; then
                diferencialColour="\e[0;31m\033[1m"
        else
                diferencialColour="\e[0;32m\033[1m"
        fi

        function consumption(){
            echo -e "${grayColour} $subscription_name \t\t\t\t\t $sub_id \t\t $budget \t\t $actual_cost \t\t ${endColour} ${diferencialColour} $diferencial_consumption ${endColour}"
        }

        consumption

        if [[ $oN_parameter_counter -eq 1 ]]; then
            if [[ $header_validation -eq 0 ]]; then
                header_consumption > $outputN
                header_validation=$((header_validation+1))
            fi
            consumption >> $outputN
        fi

        if [[ $oC_parameter_counter -eq 1 ]]; then
            if [[ $header_validation -eq 0 ]]; then
                printf '%s\n' "SuscriptionID" "Budget" "ActualCost" "Diferencia" "SubscriptionName" | paste -sd ',' > $outputC
                header_validation=$((header_validation+1))
            fi
            echo -e "$sub_id,$budget,$actual_cost,$diferencial_consumption,$subscription_name" >> $outputC

            #printf '%s\n' ${subscription_name} ${sub_id} ${budget} ${actual_cost} ${diferencial_consumption} | paste -sd ',' >> $outputC

        fi
    done
    echo " "
fi
