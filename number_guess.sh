#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess --tuples-only -c"

# generate random number between 1 and 1000
SECRET_NUMBER=$((1 + $RANDOM % 1000))

# ask for username
echo -e "\nEnter your username:"
read USERNAME

# check if user exists in database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username ILIKE '$USERNAME'")

# if user is not found
if [[ -z $USER_ID ]]
then
  # add new user to database
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username ILIKE '$USERNAME'")
  # welcome new user
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  # get user details if found
  USER_DETAILS=$($PSQL "SELECT username, games_played, best_game FROM users WHERE user_id=$USER_ID")
  # assign details to variables
  echo $USER_DETAILS | while read USERNAME BAR GAMES_PLAYED BAR BEST_GAME
  do
    # welcome message to existing user
    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# ask user to guess a number, read the input and initialise guess count
echo -e "\nGuess the secret number between 1 and 1000:"
read GUESS
GUESS_COUNT=1

while [[ ! $GUESS == $SECRET_NUMBER ]]
do
# check if guess is and integer
if [[ ! $GUESS =~ ^[0-9]+$ ]]
then
  # get new guess
  echo -e "\nThat is not an integer, guess again:"
  read GUESS
  # increment guess count
  GUESS_COUNT=$(($GUESS_COUNT+1))
# check if guess is higher than secret number, and hint to guess a lower number
elif (( $GUESS > $SECRET_NUMBER ))
then
  echo -e "\nIt's lower than that, guess again:"
  read GUESS
  GUESS_COUNT=$(($GUESS_COUNT+1))
# check if guess is lower than secret number, and hint to guess a higher number
elif (( $GUESS < $SECRET_NUMBER ))
then
  echo -e "\nIt's higher than that, guess again:"
  read GUESS
  GUESS_COUNT=$(($GUESS_COUNT+1))
fi
done

# get games played by user and increment by one
GAMES_PLAYED=$(($($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID") + 1))
# update games played
UPDATE_USER=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE user_id=$USER_ID")
# update best game to current guesses if this is their best game or they have not yet played
UPDATE_USER=$($PSQL "UPDATE users SET best_game=$GUESS_COUNT WHERE user_id=$USER_ID AND (best_game>$GUESS_COUNT OR best_game=0)")

# congratulate user on guessing the number
echo -e "\nYou guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
