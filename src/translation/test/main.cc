#include "translation/Translation.h"
#include "translation/TranslationContainer.h"

#include <iostream>

namespace
{
  bool TestFindPositive(const translation::TranslationContainer& translationContainer, const std::string& lang)
  {
    const auto translation = translationContainer.Find(lang);
    if(!translation)
    {
      std::cerr << "no translation for lang: " << lang << std::endl;
      return false;
    }
    return true;
  }

  bool TestFindNegative(const translation::TranslationContainer& translationContainer, const std::string& lang)
  {
    const auto translation = translationContainer.Find(lang);
    if(translation)
    {
      std::cerr << "unexpected translation for lang: " << lang << std::endl;
      return false;
    }
    return true;
  }
}

int main(int, char**)
{
  translation::TranslationContainer translationContainer;
  bool passed = true;
  passed = TestFindPositive(translationContainer, "de") && passed;
  passed = TestFindPositive(translationContainer, "en") && passed;
  passed = TestFindNegative(translationContainer, "fr") && passed;
  return passed ? 0 : 1;
}
