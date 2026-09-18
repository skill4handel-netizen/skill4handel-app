import '../constants/session.dart';

const skillNl = <String, String>{
  'Languages': 'Talen',
  'Teaching and tutoring': 'Lesgeven en bijles',
  'Study support': 'Studiehulp',
  'Reading and writing': 'Lezen en schrijven',
  'Translation': 'Vertalen',
  'Public speaking': 'Spreken in het openbaar',
  'Computers and internet': 'Computers en internet',
  'Programming': 'Programmeren',
  'Website and apps': 'Websites en apps',
  'Design and graphics': 'Ontwerp en grafisch werk',
  'Photography': 'Fotografie',
  'Video and audio': 'Video en audio',
  'Music': 'Muziek',
  'Art and crafts': 'Kunst en handwerk',
  'Cooking and baking': 'Koken en bakken',
  'Food and nutrition': 'Voeding',
  'Health and wellbeing': 'Gezondheid en welzijn',
  'Fitness and movement': 'Fitness en beweging',
  'Mindfulness': 'Mindfulness',
  'Child support': 'Hulp bij kinderen',
  'Senior support': 'Hulp bij ouderen',
  'Home organisation': 'Huis organiseren',
  'Cleaning and household': 'Schoonmaken en huishouden',
  'Gardening': 'Tuinieren',
  'Repairs and making': 'Repareren en maken',
  'Clothing and sewing': 'Kleding en naaien',
  'Beauty and grooming': 'Verzorging',
  'Driving support': 'Hulp bij vervoer',
  'Errands and local help': 'Boodschappen en lokale hulp',
  'Administration': 'Administratie',
  'Job search help': 'Hulp bij werk zoeken',
  'CV and applications': 'CV en sollicitaties',
  'Business basics': 'Basis ondernemerschap',
  'Money basics': 'Basis geldzaken',
  'Marketing and social media': 'Marketing en social media',
  'Events and hosting': 'Evenementen en ontvangen',
  'Sports and games': 'Sport en spel',
  'Pets and animals': 'Huisdieren',
  'Travel and culture': 'Reizen en cultuur',
  'Community support': 'Buurthulp',
};

String skillKey(String raw) {
  return raw.split('::').first.trim();
}

String skillLabel(String raw) {
  final key = skillKey(raw);
  if (key.isEmpty) return raw;
  if (Session.language == 'nl') return skillNl[key] ?? key;
  return key;
}
