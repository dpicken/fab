#ifndef translation_TranslationContainer_h
#define translation_TranslationContainer_h

#include "Translation.fwd.h"

#include <map>
#include <string>

namespace translation {

class TranslationContainer
{
public:
  TranslationContainer();

  TranslationSharedPtr Find(const std::string& lang) const;

private:
  typedef std::map<std::string, TranslationSharedPtr> Index;
  Index m_index;
};

} // namespace translation

#endif // ifndef translation_TranslationContainer_h
