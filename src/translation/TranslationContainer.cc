#include "TranslationContainer.h"

#include "Translation.h"

#include "de/Translation.h"
#include "en/Translation.h"

translation::TranslationContainer::TranslationContainer()
{
  m_index.emplace("de", std::make_shared<de::Translation>());
  m_index.emplace("en", std::make_shared<en::Translation>());
}

translation::TranslationSharedPtr translation::TranslationContainer::Find(const std::string& lang) const
{
  const auto it = m_index.find(lang);
  return it != m_index.end() ? it->second : TranslationSharedPtr();
}
