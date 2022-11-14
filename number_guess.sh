#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c "
NUMBER_ATTEMPTS=0
SECRET_NUMBER=$((1 + $RANDOM % 1000))

#Realiza todas as consultas no banco de dados atrubuindo seu resultado a variável QUERY_RESULT
SQL_QUERY(){
  QUERY_RESULT="$($PSQL "$1")"
}

#Insere um usuário no banco de dados caso ele ainda não exista
SQL_INSERT_USER(){
  SQL_QUERY "INSERT INTO users (username,games_played,best_game) VALUES('$USER_NAME', 0, 0)"
  if [[ "$QUERY_RESULT" != "INSERT 0 1" ]]
  then
    echo "User not inserted into database"
    exit 1
  fi
}

#Pegas as informações do usuário atribuindo elas as variáveis USER_ID NAME GAMES_PLAYED BEST_GAME
SQL_GET_USER(){
  SQL_QUERY "SELECT * FROM users WHERE username='$USER_NAME'"
  IFS="|" read USER_ID NAME GAMES_PLAYED BEST_GAME <<< "$QUERY_RESULT"
}

#Checa se um usário existe, caso sim, mostra a mensagem no else volta para MAIN, caso não, insere o usário no banco de dados
SQL_CHECK_EXISTENCE(){
  SQL_GET_USER
  if [[ -z $USER_ID ]]
  then
    echo "Welcome, $USER_NAME! It looks like this is your first time here."
    SQL_INSERT_USER
    SQL_GET_USER
  else    
    echo "Welcome back, $NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
}

#Sempre que uma partida termina o número de vezes jogas games_played é iincrmentado em 1 e caso 
#o número de tentativas para terminar o jogo seja menor que o menor anteriormente jogado,
#esse valor é atualizado em best_game
SQL_UPDATE_USER(){
  if [[ $BEST_GAME -gt $NUMBER_ATTEMPTS || $BEST_GAME -eq 0 ]]
  then
    SQL_QUERY "UPDATE users SET games_played=$(($GAMES_PLAYED+1)) , best_game=$NUMBER_ATTEMPTS WHERE user_id=$USER_ID"
  else
    SQL_QUERY "UPDATE users SET games_played=$(($GAMES_PLAYED+1)) WHERE user_id=$USER_ID"
  fi
}

#Onde se encontra toda a lógica do jogo
RANDOM_GAME(){
  NUMBER_ATTEMPTS=$((NUMBER_ATTEMPTS+1))
  read NUMBER_GUESS

  if [[ "$NUMBER_GUESS" =~ ^[0-9][0-9]?[0-9]?[0-9]?$ ]]
  then
    if [[ "$SECRET_NUMBER" -eq "$NUMBER_GUESS" ]]
    then
      echo "You guessed it in $NUMBER_ATTEMPTS tries. The secret number was $SECRET_NUMBER. Nice job!"
      SQL_UPDATE_USER
      exit 0
    elif [[ "$SECRET_NUMBER" -lt "$NUMBER_GUESS" ]]
    then
      echo "It's lower than that, guess again:"
      RANDOM_GAME
    else
      echo "It's higher than that, guess again:"
      RANDOM_GAME
    fi
  else
    echo "That is not an integer, guess again:"
    NUMBER_ATTEMPTS=$((NUMBER_ATTEMPTS-1))
    RANDOM_GAME
  fi
}

MAIN(){
  echo "Enter your username:"
  read USER_NAME
  SQL_CHECK_EXISTENCE
  echo "Guess the secret number between 1 and 1000:"
  RANDOM_GAME
}

MAIN