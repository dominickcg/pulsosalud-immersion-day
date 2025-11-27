"""
Lambda Layer compartido para funciones de búsqueda por similitud.
"""

from .similarity_search import (
    search_similar_informes,
    search_similar_informes_all_workers,
    get_historical_context,
    format_context_for_prompt
)

__all__ = [
    'search_similar_informes',
    'search_similar_informes_all_workers',
    'get_historical_context',
    'format_context_for_prompt'
]
