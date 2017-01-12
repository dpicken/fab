#include "translation/Translation.h"
#include "translation/TranslationContainer.h"

#include <iostream>

int main(int argc, char** argv)
{
  if(argc != 2)
  {
    std::cerr << "Syntax: " << *argv << " lang" << std::endl;
    return -1;
  }

  const auto lang = argv[1];
  const auto translation = translation::TranslationContainer().Find(lang);
  if(!translation)
  {
    std::cerr << *argv << ": no translation for lang: " << lang << std::endl;
    return -1;
  }

  std::cout << translation->HelloWorld() << std::endl;

  return 0;
}
