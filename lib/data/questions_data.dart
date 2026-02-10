import '../models/question.dart';

class QuestionsData {
  static Map<String, List<Question>> questions = {
    'Na luzie': [
      Question(
        text: 'Film w domu czy wyjście do kina?',
        option1: 'Film w domu',
        option2: 'Wyjście do kina',
      ),
      Question(
        text: 'Morze czy góry?',
        option1: 'Morze',
        option2: 'Góry',
      ),
      Question(
        text: 'Pizza czy burger?',
        option1: 'Pizza',
        option2: 'Burger',
      ),
    ],
    'Rodzinne': [
      Question(
        text: 'Gra planszowa czy karcianka?',
        option1: 'Gra planszowa',
        option2: 'Karcianka',
      ),
      Question(
        text: 'Wspólne gotowanie czy zamówienie jedzenia?',
        option1: 'Wspólne gotowanie',
        option2: 'Zamówienie jedzenia',
      ),
      Question(
        text: 'Wycieczka rowerowa czy spacer?',
        option1: 'Wycieczka rowerowa',
        option2: 'Spacer',
      ),
    ],
    'Znajomi': [
      Question(
        text: 'Impreza w domu czy w klubie?',
        option1: 'W domu',
        option2: 'W klubie',
      ),
      Question(
        text: 'Karaoke czy quiz?',
        option1: 'Karaoke',
        option2: 'Quiz',
      ),
      Question(
        text: 'Grill czy restauracja?',
        option1: 'Grill',
        option2: 'Restauracja',
      ),
    ],
    'Pikantne': [
      Question(
        text: 'Randka w ciemno czy speed dating?',
        option1: 'Randka w ciemno',
        option2: 'Speed dating',
      ),
      Question(
        text: 'Pocałunek czy przytulenie?',
        option1: 'Pocałunek',
        option2: 'Przytulenie',
      ),
      Question(
        text: 'Romantyczny wieczór czy spontaniczna przygoda?',
        option1: 'Romantyczny wieczór',
        option2: 'Spontaniczna przygoda',
      ),
    ],
    'Szalone': [
      Question(
        text: 'Skok na bungee czy skydiving?',
        option1: 'Bungee',
        option2: 'Skydiving',
      ),
      Question(
        text: 'Tatuaż czy piercing?',
        option1: 'Tatuaż',
        option2: 'Piercing',
      ),
      Question(
        text: 'Podróż autostopem czy backpacking?',
        option1: 'Autostop',
        option2: 'Backpacking',
      ),
    ],
    'Głębokie': [
      Question(
        text: 'Szczęście czy sukces?',
        option1: 'Szczęście',
        option2: 'Sukces',
      ),
      Question(
        text: 'Przeszłość czy przyszłość?',
        option1: 'Przeszłość',
        option2: 'Przyszłość',
      ),
      Question(
        text: 'Mądrość czy bogactwo?',
        option1: 'Mądrość',
        option2: 'Bogactwo',
      ),
    ],
  };

  static List<Question> getQuestionsByCategory(String category) {
    return questions[category] ?? questions['Na luzie']!;
  }
}
