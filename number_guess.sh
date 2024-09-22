#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
# Number Guessing Game
echo "Enter your username:"
read USERNAME
USER=$($PSQL "SELECT name, games_played, best_game FROM users WHERE name = '$USERNAME'")

if [[ -z $USER ]]
then
  INSERT_USER=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME')")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  IFS="|" read NAME GAMES_PLAYED BEST_GAME <<< "$USER"
  echo "Welcome back, $NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Initialize number to guess
NUMBER_TO_GUESS=$(( RANDOM % 10 + 1 ))
echo "Guess the secret number between 1 and 1000:"

# Initialize guess counter
GUESS_COUNT=0

while true
do
  read NUMBER_INPUT
  # Increment the guess count
  ((GUESS_COUNT++))

  if [[ ! "$NUMBER_INPUT" =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  elif [[ "$NUMBER_INPUT" -lt  $NUMBER_TO_GUESS ]]
  then
    echo "It's higher than that, guess again:"
  elif [[ "$NUMBER_INPUT" -gt  $NUMBER_TO_GUESS ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $NUMBER_TO_GUESS. Nice job!"
    
        # Update user stats in the database
    if [[ -n $USER ]]
    then
      # Update games played and best game if it's a new best
      UPDATE_STATS=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE name = '$USERNAME'")
      
      # Update best game if current guesses are fewer
      if [[ $GUESS_COUNT -lt $BEST_GAME || $BEST_GAME -eq 0 ]]
      then
        UPDATE_BEST=$($PSQL "UPDATE users SET best_game = $GUESS_COUNT WHERE name = '$USERNAME'")
      fi
    else
      # Update games played and best game for new user
      INSERT_STATS=$($PSQL "UPDATE users SET games_played = 1, best_game = $GUESS_COUNT WHERE name = '$USERNAME'")
    fi
    break
  fi
done
