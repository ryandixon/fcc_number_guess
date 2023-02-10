#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"

echo "Enter your username:"
read USERNAME

SELECT_USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")

if [[ -z $SELECT_USER_ID ]]
then
  # insert user info
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  if [[ $INSERT_USER_RESULT == "INSERT 0 1" ]]
  then
    # get user id
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
    # insert game info
    INSERT_GAMES_PLAYED=$($PSQL "INSERT INTO games(user_id, games_played, best_guess) VALUES($USER_ID, 0, 1000)")
    if [[ $INSERT_GAMES_PLAYED == "INSERT 0 1" ]]
    then
      echo "Welcome, $USERNAME! It looks like this is your first time here."
    fi  
  fi
else
  # get game info
  SELECT_GAMES_PLAYED=$($PSQL "SELECT games_played FROM games WHERE user_id = $SELECT_USER_ID")
  SELECT_BEST_GUESS=$($PSQL "SELECT best_guess FROM games WHERE user_id = $SELECT_USER_ID")
  echo -e "Welcome back, $USERNAME! You have played $(echo $SELECT_GAMES_PLAYED | sed -r 's/^ *| *$//g') games, and your best game took $(echo $SELECT_BEST_GUESS | sed -r 's/^ *| *$//g') guesses."
fi

NUMBER=$(( RANDOM % 1000 + 1 ))

COUNTER=0
echo "Guess the secret number between 1 and 1000:"

while [[ $NUMBER_GUESS != $NUMBER ]]
do
  ((COUNTER++))

  read NUMBER_GUESS
  if [[ $NUMBER_GUESS =~ ^[0-9]+$ ]]
  then
    if [[ $NUMBER_GUESS < $NUMBER ]]
    then
      echo "It's higher than that, guess again:"
    elif [[ $NUMBER_GUESS > $NUMBER ]]
    then
      echo "It's lower than that, guess again:"
    elif [[ $NUMBER_GUESS == $NUMBER ]]
    then
      # get user id
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
      # get current best result
      SELECT_BEST_GUESS=$($PSQL "SELECT best_guess FROM games WHERE user_id = $USER_ID")
      if [[ $COUNTER -lt $SELECT_BEST_GUESS ]]
      then
        #update best guess
        UPDATE_GUESS=$($PSQL "UPDATE games SET best_guess = $COUNTER WHERE user_id = $USER_ID")
      fi
      #update games played
      UPDATE_GAMES_PLAYED=$($PSQL "UPDATE games SET games_played = games_played + 1 WHERE user_id = $USER_ID")
      if [[ $UPDATE_GAMES_PLAYED == "UPDATE 1" ]]
      then
        echo "You guessed it in $COUNTER tries. The secret number was $NUMBER. Nice job!"
      fi
    fi
  else
    echo "That is not an integer, guess again:"
  fi
done
